from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class VacationModeCreate(BaseModel):

    resident_id: int
    start_date: date
    end_date: date

    reason: str | None = None
    emergency_contact: str | None = None

    allow_visitors: bool = False
    allow_deliveries: bool = True
    notify_security: bool = True
    monitoring_enabled: bool = True


class VacationModeResponse(BaseModel):

    id: int
    resident_id: int

    start_date: date
    end_date: date

    reason: str | None

    emergency_contact: str | None

    allow_visitors: bool
    allow_deliveries: bool
    notify_security: bool
    monitoring_enabled: bool

    status: str

    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ActiveVacationResponse(BaseModel):

    resident_name: str
    unit_number: str

    start_date: date
    end_date: date

    days_remaining: int