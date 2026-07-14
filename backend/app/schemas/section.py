from pydantic import BaseModel


class SectionCreate(BaseModel):
    property_id: int
    name: str
    description: str | None = None


class SectionResponse(BaseModel):
    id: int
    property_id: int
    name: str
    description: str | None = None

    class Config:
        from_attributes = True