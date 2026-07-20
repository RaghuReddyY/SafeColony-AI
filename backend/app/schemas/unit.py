from typing import Annotated

from pydantic import BaseModel, ConfigDict, StringConstraints


UnitNumber = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=1,
        max_length=30,
    ),
]

UnitType = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=2,
        max_length=30,
    ),
]

Floor = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=20,
    ),
]

OwnerName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=100,
    ),
]

IntercomNumber = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=20,
    ),
]


class UnitCreate(BaseModel):
    property_id: int
    section_id: int
    unit_number: UnitNumber
    unit_type: UnitType = "Apartment"
    floor: Floor | None = None
    owner_name: OwnerName | None = None
    intercom_number: IntercomNumber | None = None


class UnitResponse(BaseModel):
    id: int
    property_id: int
    section_id: int
    unit_number: str
    unit_type: str
    floor: str | None
    owner_name: str | None
    occupancy_status: str
    intercom_number: str | None
    is_active: bool

    model_config = ConfigDict(
        from_attributes=True,
    )