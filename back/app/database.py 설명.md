# FastAPI + SQLAlchemy + SQLite 설정

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# SQLite 데이터베이스 파일 경로(로컬 저장)
SQLALCHEMY_DATABASE_URL = "sqlite:///./chat_history.db"

# check_same_thread=False는 FastAPI와 SQLite를 함께 쓸 때 필요한 설정
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# DB 세션 의존성 주입을 위한 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

이 코드는 FastAPI에서 SQLAlchemy ORM을 사용하여 SQLite 데이터베이스를 연결하고 세션을 관리하는 기본 설정 코드.

주요 기능은 다음과 같음

* SQLite 데이터베이스 연결
* SQLAlchemy 엔진 생성
* ORM 모델을 위한 Base 클래스 생성
* FastAPI에서 사용할 DB 세션 의존성 제공

---

# 1. 필요한 라이브러리 import

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
```

| 라이브러리            | 설명             |
| ---------------- | -------------- |
| create_engine    | 데이터베이스 연결을 생성  |
| sessionmaker     | DB 세션 생성       |
| declarative_base | ORM 모델의 기본 클래스 |

---

# 2. SQLite 데이터베이스 경로 설정

```python
SQLALCHEMY_DATABASE_URL = "sqlite:///./chat_history.db"
```

## 의미

SQLite 데이터베이스 파일의 위치를 지정

구조

```
sqlite:///./chat_history.db
```

| 구성                | 설명                 |
| ----------------- | ------------------ |
| sqlite            | SQLite 데이터베이스 사용   |
| ///               | 로컬 파일 경로           |
| ./chat_history.db | 현재 디렉토리에 생성될 DB 파일 |

### 결과

프로젝트 실행 시 다음 파일이 생성

```
chat_history.db
```

---

# 3. SQLAlchemy Engine 생성

```python
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
```

## Engine이란?

**데이터베이스와 실제 연결을 담당하는 객체**

구조

```
FastAPI
   ↓
SQLAlchemy Session
   ↓
Engine
   ↓
Database
```

---

## check_same_thread=False 옵션

SQLite는 기본적으로 **하나의 스레드에서만 DB 접근을 허용**

하지만 FastAPI는 **멀티 스레드 환경**이기 때문에 다음 옵션이 필요

```python
connect_args={"check_same_thread": False}
```

### 역할

* 여러 요청에서 SQLite 접근 가능
* FastAPI와 SQLite 호환

---

# 4. SessionLocal 생성

```python
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)
```

## Session이란?

**DB 작업을 수행하는 객체**

예시

* SELECT
* INSERT
* UPDATE
* DELETE

---

## 주요 옵션

| 옵션               | 설명            |
| ---------------- | ------------- |
| autocommit=False | 자동 커밋 비활성화    |
| autoflush=False  | 자동 flush 비활성화 |
| bind=engine      | 사용할 DB 엔진     |

---

### 동작 예시

```python
db = SessionLocal()

db.add(user)
db.commit()
```

---

# 5. ORM Base 클래스 생성

```python
Base = declarative_base()
```

## 역할

SQLAlchemy ORM 모델의 **부모 클래스**

모든 테이블 모델은 Base를 상속 받는다.

---

### 예시

```python
class ChatMessage(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True)
    message = Column(String)
```

구조

```
Base
  ├── User
  ├── ChatMessage
  ├── News
  └── ChatHistory
```

---

# 6. DB 세션 의존성 함수

```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

## 역할

FastAPI에서 **DB 세션을 자동으로 관리**하는 의존성 함수

---

## 동작 과정

```
API 요청
   ↓
get_db() 실행
   ↓
Session 생성
   ↓
API 로직 실행
   ↓
응답 반환
   ↓
Session 자동 종료
```

---

# 7. FastAPI에서 사용하는 방법

FastAPI에서는 **Dependency Injection** 방식으로 사용

```python
from fastapi import Depends
from sqlalchemy.orm import Session

@app.get("/users")
def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()
```

---

## 실행 흐름

```
요청 발생
   ↓
Depends(get_db)
   ↓
DB Session 생성
   ↓
API 로직 실행
   ↓
Session close
```

---

# 8. 전체 구조

```
FastAPI
   ↓
Depends(get_db)
   ↓
SessionLocal
   ↓
SQLAlchemy Engine
   ↓
SQLite (chat_history.db)
```

---

# 9. 프로젝트 구조 예시

```
project
│
├─ main.py
├─ database.py
├─ models.py
├─ schemas.py
└─ chat_history.db
```

| 파일              | 역할              |
| --------------- | --------------- |
| main.py         | FastAPI 실행      |
| database.py     | DB 연결 설정        |
| models.py       | ORM 모델          |
| schemas.py      | Pydantic 데이터 모델 |
| chat_history.db | SQLite DB       |

---

# 10. 장점

이 구조의 장점

* FastAPI와 **SQLAlchemy 공식 패턴**
* 요청마다 **DB 세션 자동 관리**
* ORM 기반으로 **SQL 작성 없이 DB 사용**
* 유지보수 쉬움
