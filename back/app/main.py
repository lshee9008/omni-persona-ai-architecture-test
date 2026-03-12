from fastapi import FastAPI
from contextlib import asynccontextmanager
import redis.asyncio as aioredis
import os

from .database import engine, Base
from .routers import chat

# 서버 시작 시 SQLite 테이블 자동 생성
Base.metadata.create_all(bind=engine)

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Redis 클라이언트 생성 및 FastAPI 상태(State)에 저장
    app.state.redis = aioredis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    print("✅ Redis 및 DB 초기화 완료")
    yield
    await app.state.redis.close()

app = FastAPI(title="Omni Persona AI API", lifespan=lifespan)

# 라우터 등록
app.include_router(chat.router)

@app.get("/")
async def root():
    return {"message": "Omni Persona AI 백엔드 가동 중!"}