from pydantic import BaseModel
from app.enums.vehicle_type import VehicleType

class VehicleCreate(BaseModel):
    resident_id: int
    vehicle_number: str
    vehicle_type: VehicleType = VehicleType.CAR
    brand: str | None = None
    model: str | None = None
    color: str | None = None
    parking_slot: str | None = None


class VehicleResponse(BaseModel):
    id: int
    resident_id: int
    vehicle_number: str
    vehicle_type: VehicleType
    brand: str | None
    model: str | None
    color: str | None
    parking_slot: str | None
    is_active: bool

    class Config:
        from_attributes = True