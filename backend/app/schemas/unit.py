from pydantic import BaseModel


class UnitCreate(BaseModel):
    property_id: int
    section_id: int
    unit_number: str
    unit_type: str = "Apartment"
    floor: str | None = None
    owner_name: str | None = None
    intercom_number: str | None = None


class UnitResponse(BaseModel):
    id: int
    property_id: int
    section_id: int
    unit_number: str
    unit_type: str
    floor: str | None
    owner_name: str | None
    occupancy_status: str
    intercom_number: str | None
    is_active: bool

    class Config:
        from_attributes = True