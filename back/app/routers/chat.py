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
