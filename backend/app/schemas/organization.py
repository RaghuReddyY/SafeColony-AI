from pydantic import BaseModel, EmailStr


class OrganizationCreate(BaseModel):
    name: str
    organization_type: str
    email: EmailStr
    phone: str
    address: str
    city: str
    state: str
    country: str
    pincode: str


class OrganizationResponse(OrganizationCreate):
    id: int

    class Config:
        from_attributes = True