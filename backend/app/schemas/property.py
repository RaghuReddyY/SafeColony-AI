from pydantic import BaseModel


class PropertyCreate(BaseModel):

    organization_id: int
    
    name: str

    property_type: str

    address: str

    city: str

    state: str

    country: str

    pincode: str


class PropertyResponse(PropertyCreate):

    id: int

    class Config:
        from_attributes = True