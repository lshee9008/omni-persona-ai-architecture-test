from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    session_id: str
    message: str
    persona: Optional[str] = "친절하고 유능한 AI 어시스턴트" # 멀티 페르소나 설정용

class ChatResponse(BaseModel):
    reply: str