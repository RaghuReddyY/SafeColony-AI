from typing import Annotated

from pydantic import BaseModel, ConfigDict, StringConstraints


SectionName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=2,
        max_length=100,
    ),
]

SectionDescription = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=255,
    ),
]


class SectionCreate(BaseModel):
    property_id: int
    name: SectionName
    description: SectionDescription | None = None


class SectionResponse(BaseModel):
    id: int
    property_id: int
    name: str
    description: str | None = None

    model_config = ConfigDict(
        from_attributes=True,
    )