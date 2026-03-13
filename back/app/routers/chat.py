from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import httpx
import json
import os
from .. import models, schemas, database
# 💡 두 가지 검색 함수 모두 임포트
from ..rag import search_documents, search_web

router = APIRouter(prefix="/chat", tags=["Chat"])
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")


@router.post("/stream")
async def chat_stream_with_ai(
        request: Request,
        chat_req: schemas.ChatRequest,
        db: Session = Depends(database.get_db)
):
    redis = request.app.state.redis
    cache_key = f"chat_context:{chat_req.session_id}"

    user_msg = models.ChatMessage(session_id=chat_req.session_id, role="user", content=chat_req.message)
    db.add(user_msg)
    db.commit()

    # 💡 [하이브리드 RAG 1단계] 내부 Vector DB 검색
    db_context_list = search_documents(chat_req.message)
    db_context_str = "\n- ".join(db_context_list) if db_context_list else "관련 내부 지식 없음"

    # 💡 [하이브리드 RAG 2단계] 외부 웹 실시간 검색
    web_context_str = search_web(chat_req.message)

    # 💡 [하이브리드 RAG 3단계] 강력한 시스템 프롬프트 주입
    system_content = f"""당신은 {chat_req.persona}입니다. 한국어로 자연스럽고 친절하게 답변해주세요.
아래 제공된 [내부 데이터베이스 지식]과 [실시간 웹 검색 정보]를 모두 분석하여 답변하세요.
만약 정보가 겹치거나 다를 경우, [내부 데이터베이스 지식]을 최우선으로 신뢰하여 기재하세요.

[내부 데이터베이스 지식]
{db_context_str}

[실시간 웹 검색 정보]
{web_context_str}
"""

    cached_history = await redis.get(cache_key)
    if cached_history:
        messages = json.loads(cached_history)
        messages[0] = {"role": "system", "content": system_content}
    else:
        messages = [{"role": "system", "content": system_content}]

    messages.append({"role": "user", "content": chat_req.message})

    # 3. 제너레이터(Generator) 함수를 통한 스트리밍 처리
    async def generate_response():
        nonlocal messages
        full_reply = ""

        async with httpx.AsyncClient() as client:
            async with client.stream(
                    "POST", f"{OLLAMA_URL}/api/chat",
                    json={"model": "gemma3:4b", "messages": messages, "stream": True},
                    timeout=60.0
            ) as response:
                async for chunk in response.aiter_text():
                    if chunk:
                        try:
                            data = json.loads(chunk)
                            content = data.get("message", {}).get("content", "")
                            full_reply += content
                            yield content
                        except json.JSONDecodeError:
                            continue

        ai_msg = models.ChatMessage(session_id=chat_req.session_id, role="assistant", content=full_reply)
        db.add(ai_msg)
        db.commit()

        messages.append({"role": "assistant", "content": full_reply})
        if len(messages) > 11:
            messages = [messages[0]] + messages[-10:]

        await redis.set(cache_key, json.dumps(messages), ex=3600)

    return StreamingResponse(generate_response(), media_type="text/event-stream")