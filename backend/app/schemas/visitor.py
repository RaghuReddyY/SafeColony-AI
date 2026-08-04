from datetime import datetime

from pydantic import BaseModel

from app.enums.approval_mode import ApprovalMode
from app.enums.entry_mode import EntryMode
from app.enums.visitor_status import VisitorStatus
from app.enums.visitor_type import VisitorType


# ============================================================
# Resident Creates Visitor
# resident_id comes from JWT
# ============================================================

class ResidentVisitorCreate(BaseModel):

    visitor_name: str

    phone: str

    visitor_type: VisitorType = VisitorType.GUEST

    purpose: str | None = None

    vehicle_number: str | None = None

    expected_time: datetime | None = None

    entry_mode: EntryMode = EntryMode.QR

    visitor_photo: str | None = None

    # ============================================================
# Guard/Admin Creates Visitor
# resident_id supplied by request
# ============================================================

class VisitorCreate(BaseModel):

    resident_id: int

    visitor_name: str

    phone: str

    visitor_type: VisitorType = VisitorType.GUEST

    purpose: str | None = None

    vehicle_number: str | None = None

    expected_time: datetime | None = None

    entry_mode: EntryMode = EntryMode.QR

    visitor_photo: str | None = None

 # ============================================================
# Response
# ============================================================

class VisitorResponse(BaseModel):

    id: int

    resident_id: int

    visitor_name: str

    phone: str

    visitor_type: VisitorType

    purpose: str | None

    vehicle_number: str | None

    status: VisitorStatus

    entry_mode: EntryMode

    approval_mode: ApprovalMode | None

    visitor_photo: str | None

    created_by_guard: bool

    qr_token: str | None

    qr_code: str | None

    approved_at: datetime | None

    class Config:
        from_attributes = True