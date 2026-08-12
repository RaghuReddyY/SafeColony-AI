from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class ComplaintCreate(BaseModel):
    title: str = Field(min_length=3, max_length=150)
    description: str = Field(min_length=3, max_length=5000)
    category: str = Field(min_length=2, max_length=60)
    priority: str = Field(default="MEDIUM", pattern="^(LOW|MEDIUM|HIGH|CRITICAL)$")


class ComplaintUpdate(BaseModel):
    status: str | None = Field(default=None, pattern="^(OPEN|ASSIGNED|IN_PROGRESS|RESOLVED|CLOSED)$")
    assigned_to_user_id: int | None = None
    resolution: str | None = Field(default=None, max_length=5000)


class ComplaintEscalate(BaseModel):
    reason: str = Field(min_length=3, max_length=500)


class ComplaintResponse(BaseModel):
    id: int
    organization_id: int
    resident_id: int
    title: str
    description: str
    category: str
    priority: str
    status: str
    assigned_to_user_id: int | None
    escalated_at: datetime | None
    escalation_reason: str | None
    resolution: str | None
    resolved_at: datetime | None
    created_by_user_id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
