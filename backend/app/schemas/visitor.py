from datetime import datetime

from pydantic import BaseModel


class VisitorCreate(BaseModel):
    resident_id: int
    visitor_name: str
    phone: str
    visitor_type: str = "Guest"
    purpose: str | None = None
    vehicle_number: str | None = None
    expected_time: datetime | None = None


class VisitorResponse(BaseModel):

    id: int
    resident_id: int

    visitor_name: str

    phone: str

    visitor_type: str

    purpose: str | None

    vehicle_number: str | None

    status: str

    qr_token: str | None

    qr_code: str | None

    approved_at: datetime | None

    class Config:
        from_attributes = True