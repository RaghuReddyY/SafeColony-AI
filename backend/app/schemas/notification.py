from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, field_serializer


class NotificationCreate(BaseModel):
    user_id: int
    title: str
    message: str
    notification_type: str
    entity_type: str | None = None
    entity_id: int | None = None
    action: str | None = None
    channel: str = Field(default="IN_APP", pattern="^(IN_APP|PUSH|EMAIL|SMS|WHATSAPP)$")


class NotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    notification_type: str
    entity_type: str | None = None
    entity_id: int | None = None
    action: str | None = None
    channel: str = Field(default="IN_APP", pattern="^(IN_APP|PUSH|EMAIL|SMS|WHATSAPP)$")
    is_read: bool
    created_at: datetime

    @field_serializer("created_at")
    def serialize_created_at(self, value: datetime) -> str:
        # Existing database DateTime columns store UTC as a naive datetime.
        # Emit an explicit UTC offset so Flutter and other clients do not
        # interpret the value as local time.
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat()

    model_config = ConfigDict(from_attributes=True)