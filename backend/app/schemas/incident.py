from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class IncidentCreate(BaseModel):
    title: str = Field(min_length=3, max_length=150)
    description: str = Field(min_length=3, max_length=5000)
    incident_type: str = Field(min_length=2, max_length=50)
    severity: str = Field(default="MEDIUM", pattern="^(LOW|MEDIUM|HIGH|CRITICAL)$")
    location: str | None = Field(default=None, max_length=200)


class IncidentUpdate(BaseModel):
    status: str | None = Field(default=None, pattern="^(OPEN|INVESTIGATING|RESOLVED|CLOSED)$")
    assigned_to_user_id: int | None = None
    investigation_notes: str | None = Field(default=None, max_length=5000)
    resolution_notes: str | None = Field(default=None, max_length=5000)


class IncidentEvidenceCreate(BaseModel):
    evidence_type: str = Field(pattern="^(PHOTO|DOCUMENT|NOTE)$")
    file_url: str | None = Field(default=None, max_length=500)
    description: str | None = Field(default=None, max_length=500)


class IncidentEvidenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    incident_id: int
    evidence_type: str
    file_url: str | None
    description: str | None
    uploaded_by_user_id: int
    created_at: datetime
    updated_at: datetime


class IncidentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    organization_id: int
    title: str
    description: str
    incident_type: str
    severity: str
    status: str
    location: str | None
    created_by_user_id: int
    assigned_to_user_id: int | None
    investigation_notes: str | None
    resolution_notes: str | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime
    evidence: list[IncidentEvidenceResponse] = []


class IncidentReportResponse(BaseModel):
    total: int
    open: int
    investigating: int
    resolved: int
    closed: int
    critical: int
