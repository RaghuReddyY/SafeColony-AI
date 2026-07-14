from datetime import datetime

from pydantic import BaseModel, ConfigDict


class SecurityAlertResponse(BaseModel):

    id: int

    resident_id: int | None

    title: str

    message: str

    alert_type: str

    severity: str

    is_resolved: bool

    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )