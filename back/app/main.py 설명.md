# FastAPI + Redis 연결 예제
```python
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
```

- 이 코드는 **FastAPI 애플리케이션에서 Redis를 비동기 방식으로 연결하고 관리하는 예제**
애플리케이션 시작 시 Redis에 연결
-  종료 시 연결을 정리하며
- Redis 상태를 확인하는 API도 제공

---

# 1. 사용 라이브러리

```python
from fastapi import FastAPI
from contextlib import asynccontextmanager
import redis.asyncio as redis
import os
```

| 라이브러리               | 설명                    |
| ------------------- | --------------------- |
| FastAPI             | Python 기반 비동기 웹 프레임워크 |
| asynccontextmanager | 애플리케이션 lifecycle 관리   |
| redis.asyncio       | Redis 비동기 클라이언트       |
| os                  | 환경변수 읽기               |

---

# 2. Redis URL 설정

```python
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
```

## 설명

* Redis 서버 주소를 환경 변수에서 읽음
* 환경 변수가 없으면 기본값을 사용

### 기본값

```
redis://localhost:6379
```

### 의미

| 요소        | 설명          |
| --------- | ----------- |
| redis://  | Redis 프로토콜  |
| localhost | Redis 서버 주소 |
| 6379      | Redis 기본 포트 |

---

# 3. Redis 클라이언트 전역 변수

```python
redis_client = None
```

## 설명

Redis 연결 객체를 **전역 변수로 저장**하여
API 라우터에서 사용할 수 있도록 함

---

# 4. FastAPI Lifespan (애플리케이션 생명주기 관리)

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
```

- FastAPI의 **Lifespan 기능**을 사용하면 다음 시점을 제어할 가능

    >| 시점   | 설명          |
    >| ---- | ----------- |
    >| 앱 시작 | Redis 연결    |
    >| 앱 종료 | Redis 연결 종료 |

---

## 4-1 애플리케이션 시작 시 Redis 연결

```python
global redis_client
redis_client = redis.from_url(
    REDIS_URL,
    encoding="utf-8",
    decode_responses=True
)
print("Redis 연결 성공")
```

### 주요 옵션

| 옵션                    | 설명                   |
| --------------------- | -------------------- |
| encoding="utf-8"      | 문자열 인코딩              |
| decode_responses=True | Redis 결과를 문자열로 자동 변환 |

### 예시

Redis 값이

```
"user"
```

이라면 Python에서

```
b'user'
```

가 아니라

```
'user'
```

로 바로 사용 가능합니다.

---

## 4-2 서버 실행 유지

```python
yield
```

이 지점부터 **FastAPI 서버가 실행**

구조는 다음과 같음

```
앱 시작
   ↓
Redis 연결
   ↓
yield
   ↓
API 실행
   ↓
앱 종료
   ↓
Redis 연결 종료
```

---

## 4-3 애플리케이션 종료 시 Redis 연결 해제

```python
await redis_client.close()
```

서버 종료 시 Redis 연결을 안전하게 종료

---

# 5. FastAPI 앱 생성

```python
app = FastAPI(
    title="Omni Persona AI API",
    lifespan=lifespan
)
```

### 옵션

| 옵션       | 설명            |
| -------- | ------------- |
| title    | API 이름        |
| lifespan | 앱 시작/종료 로직 등록 |

---

# 6. 기본 API 엔드포인트

```python
@app.get("/")
async def root():
    return {"message": "AI Chatbot API is running!"}
```

### 역할

서버 상태 확인용 기본 API

### 응답 예시

```json
{
  "message": "AI Chatbot API is running!"
}
```

---

# 7. Redis Health Check API

```python
@app.get("/health/redis")
async def health_check_redis():
```

이 API는 **Redis 서버가 정상적으로 작동하는지 확인**

---

## Redis Ping 테스트

```python
is_connected = await redis_client.ping()
```

Redis의 `PING` 명령어를 실행

정상이라면

```
True
```

를 반환

---

## 응답 예시

```json
{
  "redis_connected": true
}
```

---

# 8. 전체 동작 흐름

```
서버 실행
   ↓
FastAPI 시작
   ↓
Lifespan 실행
   ↓
Redis 연결
   ↓
API 요청 처리
   ↓
/health/redis → Redis ping
   ↓
서버 종료
   ↓
Redis 연결 종료
```

---

# 9. 테스트 방법

서버 실행

```bash
uvicorn main:app --reload
```

### 기본 API

```
GET /
```

응답

```
AI Chatbot API is running!
```

---

### Redis 상태 확인

```
GET /health/redis
```

응답

```json
{
  "redis_connected": true
}
```

---

# 10. 장점

이 구조의 장점

* 서버 시작 시 **Redis 자동 연결**
* 서버 종료 시 **연결 자동 정리**
* **비동기 Redis 사용으로 높은 성능**
* Health Check API로 **운영 모니터링 가능**
