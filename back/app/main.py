from fastapi import FastAPI
from contextlib import asynccontextmanager
import redis.asyncio as redis
import os

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

redis_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    #애플리케이셔 시작 시 redis 연결 설정
    global redis_client
    redis_client = redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    print("Redis 연결 성공")
    yield
    # 애플리케이션 종료 시: 연결 해제
    await redis_client.close()

app = FastAPI(title="Omni Persona AI API", lifespan=lifespan)

@app.get("/")
async def root():
    return {"message": "AI Chatbot API is running!"}
@app.get("/health/redis")
async def health_check_redis():
    # Redis 작동 확인용 엔드포인트
    is_connected = await redis_client.ping()
    return {"redis_connected": is_connected}