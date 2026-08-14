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
    organization_code: str

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
    organization_code: str
    admin_user_id: int
    admin_email: EmailStr


# ------------------------------------------------------------------
# Guard Management
# ------------------------------------------------------------------

class GuardCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str


class GuardResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str

    class Config:
        from_attributes = True
# ------------------------------------------------------------------
# Block / Finance Administration
# ------------------------------------------------------------------

class BlockAdminCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str
    section_ids: list[int] = []


class FinanceAdminCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str


class ScopedAdminResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    role: str
    section_ids: list[int] = []
    section_names: list[str] = []


class BlockScopeResponse(BaseModel):
    section_id: int
    section_name: str
    property_id: int
