from pydantic import BaseModel, ConfigDict


class PublicPropertyResponse(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(
        from_attributes=True,
    )


class PublicSectionResponse(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(
        from_attributes=True,
    )


class PublicOrganizationResponse(BaseModel):
    organization_id: int
    organization_name: str
    organization_code: str

    properties: list[PublicPropertyResponse]

    model_config = ConfigDict(
        from_attributes=True,
    )