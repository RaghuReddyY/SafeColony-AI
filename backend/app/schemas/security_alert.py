from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class EmergencySOSCreate(BaseModel):
    emergency_type: str = Field(min_length=3, max_length=30)
    message: str | None = Field(default=None, max_length=500)
    severity: str = Field(default="CRITICAL", min_length=4, max_length=20)


class SecurityAlertResponse(BaseModel):
    id: int
    organization_id: int | None
    resident_id: int | None
    raised_by_user_id: int | None
    raised_by_name: str | None
    source_role: str | None
    unit_number: str | None
    title: str
    message: str
    alert_type: str
    severity: str
    is_resolved: bool
    resolved_by_user_id: int | None
    resolved_by_name: str | None
    resolved_at: datetime | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
