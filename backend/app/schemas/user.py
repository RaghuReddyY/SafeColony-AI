import re
from typing import Annotated
from app.enums import UserRole
from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    StringConstraints,
    field_validator,
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
    organization_code: str

    section_id: int
    unit_number: str
    resident_type: ResidentType = ResidentType.OWNER

    full_name: FullName
    email: EmailStr
    phone: Phone
    password: Password

    @field_validator("unit_number")
    @classmethod
    def validate_unit_number(cls, value: str) -> str:
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