from pydantic import BaseModel
from typing import Optional


class QRScanRequest(BaseModel):
    qr_token: str


class QRScanResponse(BaseModel):
    id: int
    visitor_name: str
    resident_id: int
    phone: str
    visitor_type: str
    purpose: Optional[str] = None
    vehicle_number: Optional[str] = None
    status: str