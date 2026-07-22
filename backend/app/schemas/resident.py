from datetime import date
from typing import Annotated

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    StringConstraints,
)


FullName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=2,
        max_length=100,
    ),
]

Phone = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=10,
        max_length=20,
    ),
]

ResidentType = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=3,
        max_length=20,
    ),
]

Gender = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=20,
    ),
]

EmergencyContact = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=20,
    ),
]

EmergencyContactName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=100,
    ),
]


class ResidentCreate(BaseModel):
    """
    Used only by Admin when assigning an already
    registered user to a unit.
    """

    user_id: int
    unit_id: int
    resident_type: ResidentType = "OWNER"
    gender: Gender | None = None
    date_of_birth: date | None = None
    emergency_contact: EmergencyContact | None = None
    emergency_contact_name: EmergencyContactName | None = None
    is_primary: bool = False


class ResidentResponse(BaseModel):
    id: int
    user_id: int

    unit_id: int | None

    full_name: str
    email: EmailStr | None
    phone: str | None

    resident_type: str
    status: str

    gender: str | None
    is_primary: bool
    is_active: bool

    model_config = ConfigDict(
        from_attributes=True,
    )


class ResidentProfileResponse(BaseModel):
    id: int
    user_id: int

    full_name: str
    email: EmailStr | None
    phone: str | None

    resident_type: str
    status: str

    gender: str | None
    date_of_birth: date | None

    emergency_contact: str | None
    emergency_contact_name: str | None

    unit_id: int | None

    model_config = ConfigDict(
        from_attributes=True,
    )


class ResidentProfileUpdate(BaseModel):
    full_name: FullName
    email: EmailStr | None = None
    phone: Phone

    gender: Gender | None = None
    date_of_birth: date | None = None

    emergency_contact: EmergencyContact | None = None
    emergency_contact_name: EmergencyContactName | None = None