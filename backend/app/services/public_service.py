from app.repositories.public_repository import PublicRepository
from app.schemas.public import (
    PublicOrganizationResponse,
    PublicPropertyResponse,
    PublicSectionResponse,
)


class PublicService:

    def __init__(self, db):
        self.repository = PublicRepository(db)

    # --------------------------------------------------
    # Organization
    # --------------------------------------------------

    def get_organization(
        self,
        organization_code: str,
    ) -> PublicOrganizationResponse:

        organization = self.repository.get_organization_by_code(
            organization_code
        )

        if organization is None:
            raise ValueError("Invalid organization code.")

        properties = [
            PublicPropertyResponse(
                id=property.id,
                name=property.name,
            )
            for property in organization.properties
        ]

        return PublicOrganizationResponse(
            organization_id=organization.id,
            organization_name=organization.name,
            organization_code=organization.organization_code,
            properties=properties,
        )

    # --------------------------------------------------
    # Sections
    # --------------------------------------------------

    def get_sections(
        self,
        property_id: int,
    ) -> list[PublicSectionResponse]:

        sections = self.repository.get_sections_by_property(
            property_id
        )

        return [
            PublicSectionResponse(
                id=section.id,
                name=section.name,
            )
            for section in sections
        ]