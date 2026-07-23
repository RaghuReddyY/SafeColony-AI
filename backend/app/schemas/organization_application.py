from pydantic import BaseModel, EmailStr, Field
from typing import Optional

from app.enums import OrganizationApplicationStatus


class OrganizationApplicationCreate(BaseModel):
    organization_name: str = Field(..., max_length=150)
    organization_type: str = Field(..., max_length=50)

    contact_person: str = Field(..., max_length=100)

    email: EmailStr

    phone: str = Field(..., max_length=20)

    password: str = Field(..., min_length=6)

    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    pincode: Optional[str] = None


class OrganizationApplicationResponse(BaseModel):
    id: int

    organization_name: str
    organization_type: str

    contact_person: str

    email: str
    phone: str

    status: OrganizationApplicationStatus

    class Config:
        from_attributes = True


class OrganizationApplicationApproveRequest(BaseModel):
    pass


class OrganizationApplicationRejectRequest(BaseModel):
    reason: str = Field(..., min_length=3, max_length=500)