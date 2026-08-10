from pydantic import BaseModel


class GuardPropertyResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class GuardSectionResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class GuardUnitResponse(BaseModel):
    id: int
    unit_number: str

    class Config:
        from_attributes = True


class GuardResidentResponse(BaseModel):
    id: int
    full_name: str

    class Config:
        from_attributes = True