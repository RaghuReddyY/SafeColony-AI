from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CommunityServiceCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str = Field(min_length=2, max_length=80)
    phone: str = Field(min_length=5, max_length=30)
    work_description: str = Field(min_length=2, max_length=255)
    notes: str | None = Field(default=None, max_length=1000)


class CommunityServiceUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    category: str | None = Field(default=None, min_length=2, max_length=80)
    phone: str | None = Field(default=None, min_length=5, max_length=30)
    work_description: str | None = Field(default=None, min_length=2, max_length=255)
    notes: str | None = Field(default=None, max_length=1000)
    is_active: bool | None = None


class CommunityServiceResponse(BaseModel):
    id: int
    name: str
    category: str
    phone: str
    work_description: str
    notes: str | None = None
    is_active: bool
    created_by_name: str | None = None
    updated_by_name: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
