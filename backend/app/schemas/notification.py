from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class NotificationCreate(BaseModel):
    user_id: int
    title: str
    message: str
    notification_type: str
    channel: str = Field(default="IN_APP", pattern="^(IN_APP|PUSH|EMAIL|SMS|WHATSAPP)$")


class NotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    notification_type: str
    channel: str = Field(default="IN_APP", pattern="^(IN_APP|PUSH|EMAIL|SMS|WHATSAPP)$")
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)