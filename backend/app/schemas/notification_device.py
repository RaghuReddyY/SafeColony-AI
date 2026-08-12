from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class NotificationDeviceRegister(BaseModel):
    token: str = Field(min_length=10, max_length=500)
    platform: str = Field(pattern="^(ANDROID|IOS|WEB)$")


class NotificationDeviceResponse(BaseModel):
    id: int
    user_id: int
    token: str
    platform: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
