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