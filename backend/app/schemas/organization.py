from pydantic import BaseModel, EmailStr


# ------------------------------------------------------------------
# Existing CRUD Schemas
# ------------------------------------------------------------------

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


# ------------------------------------------------------------------
# Organization Onboarding Schemas
# ------------------------------------------------------------------

class OrganizationAdminCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str


class OrganizationOnboardRequest(BaseModel):
    organization: OrganizationCreate
    admin: OrganizationAdminCreate


class OrganizationOnboardResponse(BaseModel):
    message: str
    organization_id: int
    organization_name: str
    admin_user_id: int
    admin_email: EmailStr