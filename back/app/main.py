from fastapi import FastAPI
from contextlib import asynccontextmanager
import redis.asyncio as aioredis
import os
from pydantic import BaseModel

from .database import engine, Base
from .routers import chat
from .rag import init_rag, add_document  # 💡 추가됨

Base.metadata.create_all(bind=engine)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.redis = aioredis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    init_rag() # 💡 애플리케이션 시작 시 Vector DB 로딩
    print("✅ Redis, DB, RAG 초기화 완료")
    yield
    await app.state.redis.close()

app = FastAPI(title="Omni Persona AI API", lifespan=lifespan)
app.include_router(chat.router)

# 💡 실시간 지식 주입용 엔드포인트 추가
class KnowledgeRequest(BaseModel):
    text: str

@app.post("/knowledge")
async def teach_ai(req: KnowledgeRequest):
    add_document(req.text)
    return {"message": "새로운 지식이 Vector DB에 성공적으로 저장되었습니다!", "learned_text": req.text}

@app.get("/")
async def root():
    return {"message": "Omni Persona AI 백엔드 가동 중!"}