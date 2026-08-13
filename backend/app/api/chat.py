from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.schemas.chat import (
    ChatCommunityResponse,
    ChatConversationResponse,
    ChatMessageCreate,
    ChatMessageUpdate,
    ChatMessageResponse,
    ChatUserResponse,
)
from app.security.permissions import Permissions
from app.services.chat_service import ChatService

router = APIRouter(prefix="/chat", tags=["Community Chat"])


def get_service(db: Session = Depends(get_db)) -> ChatService:
    return ChatService(ChatRepository(db))


@router.get(
    "/users",
    response_model=list[ChatUserResponse],
    dependencies=[Depends(require_permission(Permissions.CHAT_VIEW))],
)
def users(
    search: str | None = None,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.users(current_user, search)


@router.get(
    "/conversations",
    response_model=list[ChatConversationResponse],
    dependencies=[Depends(require_permission(Permissions.CHAT_VIEW))],
)
def conversations(
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.list_conversations(current_user)


@router.get(
    "/community",
    response_model=ChatCommunityResponse,
    dependencies=[Depends(require_permission(Permissions.CHAT_VIEW))],
)
def community(
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return {"conversation": service.community(current_user)}


@router.post(
    "/direct/{target_user_id}",
    response_model=ChatConversationResponse,
    dependencies=[Depends(require_permission(Permissions.CHAT_SEND))],
)
def direct(
    target_user_id: int,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.start_direct(current_user, target_user_id)


@router.get(
    "/conversations/{conversation_id}/messages",
    response_model=list[ChatMessageResponse],
    dependencies=[Depends(require_permission(Permissions.CHAT_VIEW))],
)
def messages(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.messages(current_user, conversation_id)


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=ChatMessageResponse,
    dependencies=[Depends(require_permission(Permissions.CHAT_SEND))],
)
def send_message(
    conversation_id: int,
    data: ChatMessageCreate,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.send(current_user, conversation_id, data.content)




@router.put(
    "/conversations/{conversation_id}/messages/{message_id}",
    response_model=ChatMessageResponse,
    dependencies=[Depends(require_permission(Permissions.CHAT_SEND))],
)
def edit_message(
    conversation_id: int,
    message_id: int,
    data: ChatMessageUpdate,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.edit(current_user, conversation_id, message_id, data.content)


@router.delete(
    "/conversations/{conversation_id}/messages/{message_id}",
    response_model=ChatMessageResponse,
    dependencies=[Depends(require_permission(Permissions.CHAT_SEND))],
)
def delete_message(
    conversation_id: int,
    message_id: int,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.delete(current_user, conversation_id, message_id)

@router.post(
    "/conversations/{conversation_id}/read",
    dependencies=[Depends(require_permission(Permissions.CHAT_VIEW))],
)
def mark_read(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    service: ChatService = Depends(get_service),
):
    return service.mark_read(current_user, conversation_id)
