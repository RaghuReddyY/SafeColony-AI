from pydantic import BaseModel


class QRScanRequest(BaseModel):
    qr_token: str


class QRScanResponse(BaseModel):
    visitor_name: str
    resident_id: int
    status: str