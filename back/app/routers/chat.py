from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import httpx
import json
import os
from .. import models, schemas, database

router = APIRouter(prefix="/chat", tags=["Chat"])

# docker-compose.yml에서 설정한 Ollama 주소
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")


@router.post("/", response_model=schemas.ChatResponse)
async def chat_with_ai(
        request: Request,
        chat_req: schemas.ChatRequest,
        db: Session = Depends(database.get_db)
):
    # 전역 상태에 저장해둔 Redis 클라이언트 가져오기
    redis = request.app.state.redis
    cache_key = f"chat_context:{chat_req.session_id}"

    # 1. 사용자 메시지를 SQLite에 영구 저장
    user_msg = models.ChatMessage(session_id=chat_req.session_id, role="user", content=chat_req.message)
    db.add(user_msg)
    db.commit()

    # 2. Redis에서 이전 대화 맥락(Context) 가져오기
    cached_history = await redis.get(cache_key)

    if cached_history:
        messages = json.loads(cached_history)
    else:
        # 이전 대화가 없다면 시스템 프롬프트(페르소나) 초기화
        messages = [{"role": "system", "content": f"당신은 {chat_req.persona}입니다. 한국어로 자연스럽고 명확하게 답변해주세요."}]

    # 현재 사용자의 질문 추가
    messages.append({"role": "user", "content": chat_req.message})

    # 3. Ollama (로컬 LLM) API 호출
    async with httpx.AsyncClient() as client:
        try:
            # gemma3:4b 모델 사용 (원하는 모델로 변경 가능)
            response = await client.post(
                f"{OLLAMA_URL}/api/chat",
                json={"model": "gemma3:4b", "messages": messages, "stream": False},
                timeout=60.0
            )
            response.raise_for_status()
            ai_reply = response.json()["message"]["content"]
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Ollama 연동 오류: {str(e)}")

    # 4. AI 응답을 SQLite에 영구 저장
    ai_msg = models.ChatMessage(session_id=chat_req.session_id, role="assistant", content=ai_reply)
    db.add(ai_msg)
    db.commit()

    # 5. Redis 컨텍스트 업데이트 (토큰 절약을 위해 최근 10개 대화만 유지)
    messages.append({"role": "assistant", "content": ai_reply})
    if len(messages) > 11:
        messages = [messages[0]] + messages[-10:]  # 시스템 프롬프트(0번) 유지 + 최근 10개

    # Redis에 1시간(3600초) 동안 저장 (메모리 관리)
    await redis.set(cache_key, json.dumps(messages), ex=3600)

    # 6. Flutter로 결과 반환
    return schemas.ChatResponse(reply=ai_reply)