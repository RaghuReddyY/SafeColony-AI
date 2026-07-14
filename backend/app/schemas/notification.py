from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationCreate(BaseModel):
    resident_id: int
    title: str
    message: str
    notification_type: str


class NotificationResponse(BaseModel):
    id: int
    resident_id: int
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)