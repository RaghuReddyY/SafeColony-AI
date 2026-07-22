from typing import Annotated

from pydantic import (
    BaseModel,
    ConfigDict,
    StringConstraints,
)

from app.enums import UnitType, OccupancyStatus


UnitNumber = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=1,
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

    unit_type: UnitType = UnitType.APARTMENT

    floor: Floor | None = None

    owner_name: OwnerName | None = None

    intercom_number: IntercomNumber | None = None



class UnitResponse(BaseModel):

    id: int

    property_id: int

    section_id: int

    unit_number: str

    unit_type: UnitType

    floor: str | None

    owner_name: str | None

    occupancy_status: OccupancyStatus

    intercom_number: str | None

    is_active: bool


    model_config = ConfigDict(
        from_attributes=True,
    )



class UnitUpdate(BaseModel):

    unit_number: UnitNumber | None = None

    unit_type: UnitType | None = None

    floor: Floor | None = None

    owner_name: OwnerName | None = None

    intercom_number: IntercomNumber | None = None