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

    resident_id: int

    vehicle_number: str

    vehicle_type: VehicleType

    brand: str | None = None

    model: str | None = None

    color: str | None = None

    parking_slot: str | None = None

    status: VehicleStatus

    entry_time: datetime | None = None

    exit_time: datetime | None = None

    entered_by: str | None = None

    exited_by: str | None = None

    is_active: bool

    created_at: datetime

    updated_at: datetime

    class Config:
        from_attributes = True