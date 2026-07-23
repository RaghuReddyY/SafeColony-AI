from pydantic import BaseModel

from app.enums import PropertyType


class PropertyCreate(BaseModel):

    name: str

    property_type: PropertyType

    address: str

    city: str

    state: str

    country: str

    pincode: str


class PropertyResponse(PropertyCreate):

    id: int

    organization_id: int

    class Config:
        from_attributes = True