from datetime import datetime

from pydantic import BaseModel

from app.enums.vehicle_status import VehicleStatus
from app.enums.vehicle_type import VehicleType


# ==================================================
# Create Vehicle
# ==================================================

class VehicleCreate(BaseModel):
    resident_id: int
    vehicle_number: str
    vehicle_type: VehicleType = VehicleType.CAR
    brand: str | None = None
    model: str | None = None
    color: str | None = None
    parking_slot: str | None = None


# ==================================================
# Vehicle Response
# ==================================================
class VehicleResponse(BaseModel):
    id: int

    # Ownership
    resident_id: int

    # Display Fields (derived from Resident -> Unit -> Section -> Property)
    resident_name: str | None = None
    property_name: str | None = None
    section_name: str | None = None
    unit_number: str | None = None

    # Vehicle Details
    vehicle_number: str
    vehicle_type: VehicleType
    brand: str | None = None
    model: str | None = None
    color: str | None = None
    parking_slot: str | None = None

    # Guard Operations
    status: VehicleStatus
    entry_time: datetime | None = None
    exit_time: datetime | None = None
    entered_by: str | None = None
    exited_by: str | None = None

    # Status
    is_active: bool

    # Audit
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True