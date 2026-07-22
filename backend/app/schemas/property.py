from pydantic import BaseModel
from app.enums import PropertyType

class PropertyCreate(BaseModel):

    organization_id: int
    
    name: str

    property_type: PropertyType

    address: str

    city: str

    state: str

    country: str

    pincode: str


class PropertyResponse(PropertyCreate):

    id: int

    class Config:
        from_attributes = True