from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.ai.assistant import AIAssistant
from app.auth.dependencies import get_current_user
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.ai_assistant import AIChatRequest, AIChatResponse

router = APIRouter(prefix="/ai", tags=["AI Assistant"])


@router.post("/chat", response_model=AIChatResponse)
def chat(
    data: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    assistant = AIAssistant(db)
    return AIChatResponse(message=assistant.chat(current_user, data.messages))
