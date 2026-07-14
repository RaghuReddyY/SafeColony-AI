from datetime import date

from pydantic import BaseModel, EmailStr, ConfigDict


class ResidentCreate(BaseModel):
    unit_id: int
    full_name: str
    email: EmailStr | None = None
    phone: str
    resident_type: str = "OWNER"
    gender: str | None = None
    date_of_birth: date | None = None
    emergency_contact: str | None = None
    emergency_contact_name: str | None = None
    is_primary: bool = False


class ResidentResponse(BaseModel):
    id: int
    unit_id: int
    full_name: str
    email: EmailStr | None
    phone: str
    resident_type: str
    gender: str | None
    is_primary: bool
    is_active: bool

    class Config:
        from_attributes = True

class ResidentProfileResponse(BaseModel):

    id: int
    full_name: str
    email: str | None
    phone: str
    resident_type: str
    gender: str | None
    date_of_birth: date | None
    emergency_contact: str | None
    emergency_contact_name: str | None
    unit_id: int

    model_config = ConfigDict(from_attributes=True)


class ResidentProfileUpdate(BaseModel):

    full_name: str
    email: str | None = None
    gender: str | None = None
    date_of_birth: date | None = None
    emergency_contact: str | None = None
    emergency_contact_name: str | None = None