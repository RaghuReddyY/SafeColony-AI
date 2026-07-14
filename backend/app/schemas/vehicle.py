from pydantic import BaseModel


class VehicleCreate(BaseModel):
    resident_id: int
    vehicle_number: str
    vehicle_type: str = "Car"
    brand: str | None = None
    model: str | None = None
    color: str | None = None
    parking_slot: str | None = None


class VehicleResponse(BaseModel):
    id: int
    resident_id: int
    vehicle_number: str
    vehicle_type: str
    brand: str | None
    model: str | None
    color: str | None
    parking_slot: str | None
    is_active: bool

    class Config:
        from_attributes = True