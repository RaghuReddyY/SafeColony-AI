from datetime import datetime
from pydantic import BaseModel, Field


class ChatUserResponse(BaseModel):
    id: int
    full_name: str
    role: str


class ChatMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class ChatMessageUpdate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class ChatMessageResponse(BaseModel):
    id: int
    conversation_id: int
    sender_user_id: int
    sender_name: str
    sender_role: str
    content: str
    created_at: datetime
    updated_at: datetime | None = None
    is_edited: bool = False
    is_deleted: bool = False


class ChatConversationResponse(BaseModel):
    id: int
    conversation_type: str
    name: str | None = None
    participants: list[ChatUserResponse]
    last_message: ChatMessageResponse | None = None
    unread_count: int = 0
    updated_at: datetime


class ChatCommunityResponse(BaseModel):
    conversation: ChatConversationResponse
