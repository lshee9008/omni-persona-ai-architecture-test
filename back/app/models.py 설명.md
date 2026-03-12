# ChatMessage ORM 모델 (SQLAlchemy)
```python
from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime
from .database import Base

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, index=True) # 기기 ID 또는 사용자 세션 ID
    role = Column(String) # 'user' 또는 'assistant'
    content = Column(Text) # 대화 내용
    created_at = Column(DateTime, default=datetime.utcnow)
```

이 코드는 **SQLAlchemy ORM을 사용하여 채팅 메시지를 저장하는 데이터베이스 테이블 모델**을 정의

주요 역할은 다음과 같습니다.

* 사용자와 AI의 **대화 기록 저장**
* 세션별 **대화 관리**
* 메시지 **생성 시간 기록**

---

# 1. 필요한 라이브러리 import

```python
from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime
from .database import Base
```

| 라이브러리    | 설명                        |
| -------- | ------------------------- |
| Column   | 테이블 컬럼 정의                 |
| Integer  | 정수 타입                     |
| String   | 문자열 타입                    |
| Text     | 긴 문자열 저장                  |
| DateTime | 날짜/시간 데이터                 |
| datetime | 현재 시간 생성                  |
| Base     | SQLAlchemy ORM 모델의 기본 클래스 |

---

# 2. ChatMessage 모델 정의

```python
class ChatMessage(Base):
```

## 의미

SQLAlchemy ORM 모델을 정의

이 클래스는 **데이터베이스 테이블과 매핑(mapping)**

구조

```
Python Class  →  Database Table
ChatMessage   →  chat_messages
```

---

# 3. 테이블 이름 설정

```python
__tablename__ = "chat_messages"
```

## 의미

데이터베이스에 생성될 **테이블 이름**

생성되는 테이블

```
chat_messages
```

---

# 4. id 컬럼 (Primary Key)

```python
id = Column(Integer, primary_key=True, index=True)
```

## 역할

각 메시지를 구분하는 **고유 ID**

### 옵션

| 옵션               | 설명       |
| ---------------- | -------- |
| Integer          | 정수 타입    |
| primary_key=True | 기본 키     |
| index=True       | 검색 성능 향상 |

---

### 예시

| id | session_id | role      | content |
| -- | ---------- | --------- | ------- |
| 1  | user123    | user      | 안녕      |
| 2  | user123    | assistant | 안녕하세요   |

---

# 5. session_id 컬럼

```python
session_id = Column(String, index=True)
```

## 역할

사용자의 **대화 세션을 구분하는 ID**

### 사용 목적

* 사용자별 대화 관리
* 채팅 히스토리 조회
* 멀티 유저 지원

---

### 예시

| session_id  | 설명      |
| ----------- | ------- |
| user123     | 사용자 ID  |
| session_abc | 웹 세션    |
| device_xyz  | 디바이스 ID |

---

### index=True 이유

```python
index=True
```

검색 성능 향상

예시 쿼리

```
SELECT * FROM chat_messages
WHERE session_id = 'user123'
```

---

# 6. role 컬럼

```python
role = Column(String)
```

## 역할

메시지 작성자를 구분

| 값         | 의미      |
| --------- | ------- |
| user      | 사용자 메시지 |
| assistant | AI 응답   |

---

### 예시 데이터

| role      | content             |
| --------- | ------------------- |
| user      | 벌크업 식단 추천해줘         |
| assistant | 단백질 섭취를 늘리는 것이 좋습니다 |

---

# 7. content 컬럼

```python
content = Column(Text)
```

## 역할

실제 **대화 내용 저장**

### Text 타입 사용하는 이유

채팅 메시지는 길어질 수 있기 때문임

| 타입     | 특징     |
| ------ | ------ |
| String | 짧은 문자열 |
| Text   | 긴 문자열  |

---

### 예시

```
"FastAPI는 Python 기반의 고성능 웹 프레임워크입니다."
```

---

# 8. created_at 컬럼

```python
created_at = Column(DateTime, default=datetime.utcnow)
```

## 역할

메시지가 생성된 **시간 기록**

---

### default 옵션

```python
default=datetime.utcnow
```

데이터가 생성될 때 자동으로 **현재 UTC 시간 저장**

---

### 예시

| id | role      | content | created_at          |
| -- | --------- | ------- | ------------------- |
| 1  | user      | 안녕      | 2026-03-12 10:00:01 |
| 2  | assistant | 안녕하세요   | 2026-03-12 10:00:02 |

---

# 9. 실제 데이터베이스 구조

생성되는 테이블 구조

```
chat_messages
│
├── id (Primary Key)
├── session_id
├── role
├── content
└── created_at
```

---

# 10. 테이블 생성 방법

SQLAlchemy에서 다음 코드로 테이블 생성

```python
from database import engine
from models import Base

Base.metadata.create_all(bind=engine)
```

---

# 11. 데이터 저장 예시

```python
message = ChatMessage(
    session_id="user123",
    role="user",
    content="FastAPI가 뭐야?"
)

db.add(message)
db.commit()
```

---

# 12. 채팅 기록 조회 예시

```python
history = db.query(ChatMessage)\
    .filter(ChatMessage.session_id == "user123")\
    .order_by(ChatMessage.created_at)\
    .all()
```

---

# 13. 채팅 시스템 데이터 흐름

```
사용자 메시지
     ↓
FastAPI API
     ↓
ChatMessage 테이블 저장
     ↓
AI 응답 생성
     ↓
AI 응답 저장
     ↓
대화 기록 유지
```

---

# 14. 실제 채팅 데이터 예시

| id | session_id | role      | content           | created_at |
| -- | ---------- | --------- | ----------------- | ---------- |
| 1  | user123    | user      | 안녕                | 10:00      |
| 2  | user123    | assistant | 안녕하세요             | 10:00      |
| 3  | user123    | user      | FastAPI 뭐야        | 10:01      |
| 4  | user123    | assistant | Python 웹 프레임워크입니다 | 10:01      |

---

# 15. 이 구조의 장점

### 1️⃣ 대화 기록 저장 가능

AI 챗봇의 **대화 히스토리 유지**

---

### 2️⃣ 세션 기반 대화 관리

여러 사용자 동시 채팅 가능

---

### 3️⃣ 시간 기반 정렬 가능

대화 흐름 유지

```
ORDER BY created_at
```

---

### 4️⃣ AI 컨텍스트 유지 가능

예시

```
User: 오늘 날씨 어때?
AI: 맑습니다

User: 그러면 운동하기 좋을까?
```

AI가 **이전 대화 기억 가능**
