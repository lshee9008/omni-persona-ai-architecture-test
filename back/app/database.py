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