from datetime import datetime

from pydantic import BaseModel, Field


class NotificationTemplateCreate(BaseModel):
    code: str = Field(min_length=2, max_length=80)
    title_template: str = Field(min_length=1, max_length=200)
    message_template: str = Field(min_length=1, max_length=5000)
    channel: str = Field(default="IN_APP", pattern="^(IN_APP|PUSH|EMAIL|SMS|WHATSAPP)$")


class NotificationTemplateResponse(NotificationTemplateCreate):
    id: int
    organization_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime


class NotificationDeliveryResponse(BaseModel):
    id: int
    notification_id: int
    channel: str
    destination: str | None
    status: str
    attempts: int
    provider_message_id: str | None
    last_error: str | None
    sent_at: datetime | None
    created_at: datetime
    updated_at: datetime
