from pydantic import BaseModel, EmailStr, field_validator

from app.enums import UserRole


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


# ------------------------------------------------------------------
# Organization User Management
# ------------------------------------------------------------------

class OrganizationUserCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str
    role: UserRole
    section_ids: list[int] = []

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 3:
            raise ValueError("Full name must contain at least 3 characters.")
        return value

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 10:
            raise ValueError("Enter a valid mobile number.")
        return value

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must contain at least 8 characters.")
        if not any(c.isupper() for c in value):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not any(c.islower() for c in value):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not any(c.isdigit() for c in value):
            raise ValueError("Password must contain at least one number.")
        return value


class OrganizationUserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    role: UserRole
    status: str
    is_active: bool
    section_ids: list[int] = []
    section_names: list[str] = []

    class Config:
        from_attributes = True
