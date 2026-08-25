import re
from typing import Annotated
from app.enums import UserRole
from pydantic import (
    BaseModel,
    Field,
    ConfigDict,
    EmailStr,
    StringConstraints,
    field_validator,
    model_validator,
)
from app.enums import ResidentType

# ------------------------------------------------------------------
# Reusable Types
# ------------------------------------------------------------------

FullName = Annotated[
    str,
    StringConstraints(
        min_length=3,
        max_length=100,
        strip_whitespace=True,
    ),
]

Phone = Annotated[
    str,
    StringConstraints(
        min_length=10,
        max_length=20,
        strip_whitespace=True,
    ),
]

Password = Annotated[
    str,
    StringConstraints(
        min_length=8,
        max_length=100,
    ),
]

Role = Annotated[
    str,
    StringConstraints(
        min_length=3,
        max_length=30,
    ),
]


# ------------------------------------------------------------------
# User Registration
# ------------------------------------------------------------------

class UserRegister(BaseModel):
    organization_code: str | None = None

    section_id: int | None = None
    unit_number: str | None = None
    resident_type: ResidentType = ResidentType.OWNER

    full_name: FullName
    email: EmailStr
    phone: Phone
    password: Password
    family_join_code: str | None = None

    @model_validator(mode="after")
    def validate_location(self):
        if self.family_join_code:
            return self
        if not self.organization_code:
            raise ValueError("Organization code is required for Owner or Tenant registration.")
        if self.section_id is None or not self.unit_number:
            raise ValueError("Section and unit number are required for Owner or Tenant registration.")
        return self

    @field_validator("unit_number")
    @classmethod
    def validate_unit_number(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip().upper()

        if not value:
            raise ValueError("Unit number is required.")

        return value

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:

        if not re.search(r"[A-Z]", value):
            raise ValueError(
                "Password must contain at least one uppercase letter."
            )

        if not re.search(r"[a-z]", value):
            raise ValueError(
                "Password must contain at least one lowercase letter."
            )

        if not re.search(r"\d", value):
            raise ValueError(
                "Password must contain at least one number."
            )

        return value
# ------------------------------------------------------------------
# Registration Response
# ------------------------------------------------------------------

class RegisterResponse(BaseModel):
    message: str
    user_id: int
    status: str
    
# ------------------------------------------------------------------
# User Response
# ------------------------------------------------------------------

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    role: UserRole
    is_active: bool
    organization_id: int | None = None
    organization_code: str | None = None
    organization_name: str | None = None
    section_names: list[str] = []

    model_config = ConfigDict(
        from_attributes=True,
    )


# ------------------------------------------------------------------
# Change Password
# ------------------------------------------------------------------

class ChangePasswordRequest(BaseModel):
    current_password: Password
    new_password: Password

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, value: str) -> str:

        if not re.search(r"[A-Z]", value):
            raise ValueError(
                "Password must contain at least one uppercase letter."
            )

        if not re.search(r"[a-z]", value):
            raise ValueError(
                "Password must contain at least one lowercase letter."
            )

        if not re.search(r"\d", value):
            raise ValueError(
                "Password must contain at least one number."
            )

        return value


# ------------------------------------------------------------------
# User Update (Future Use)
# ------------------------------------------------------------------

class UserUpdate(BaseModel):
    full_name: FullName
    email: EmailStr
    phone: Phone

class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    message: str
    expires_in_minutes: int
    dev_reset_token: str | None = None


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    token: str = Field(min_length=16, max_length=128)
    new_password: str = Field(min_length=8, max_length=100)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, value: str) -> str:
        if not re.search(r"[A-Z]", value):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", value):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not re.search(r"\d", value):
            raise ValueError("Password must contain at least one number.")
        return value
