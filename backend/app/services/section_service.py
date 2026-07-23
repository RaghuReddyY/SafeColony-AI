from fastapi import HTTPException, status

from app.models.section import Section


class SectionService:

    def __init__(
        self,
        section_repo,
        property_repo,
    ):
        self.section_repo = section_repo
        self.property_repo = property_repo

    def create(
        self,
        current_user,
        data,
    ):

        property_obj = self.property_repo.get(data.property_id)

        if (
            property_obj is None
            or property_obj.organization_id != current_user.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Property not found.",
            )

        if self.section_repo.exists_by_name(
            data.property_id,
            data.name,
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Section already exists.",
            )

        section = Section(
            property_id=data.property_id,
            name=data.name,
            description=data.description,
        )

        return self.section_repo.create(section)

    def get_all(
        self,
        current_user,
    ):

        sections = []

        properties = self.property_repo.get_by_organization(
            current_user.organization_id
        )

        for property_obj in properties:
            sections.extend(
                self.section_repo.get_by_property(property_obj.id)
            )

        return sections

    def get(
        self,
        current_user,
        section_id,
    ):

        section = self.section_repo.get_by_id(section_id)

        if not section:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Section not found.",
            )

        property_obj = self.property_repo.get(section.property_id)

        if property_obj.organization_id != current_user.organization_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Section not found.",
            )

        return section

    def get_by_property(
        self,
        current_user,
        property_id,
    ):

        property_obj = self.property_repo.get(property_id)

        if (
            property_obj is None
            or property_obj.organization_id != current_user.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Property not found.",
            )

        return self.section_repo.get_by_property(property_id)

    def update(
        self,
        current_user,
        section_id,
        data,
    ):

        section = self.get(
            current_user,
            section_id,
        )

        if (
            section.name.lower() != data.name.lower()
            and self.section_repo.exists_by_name(
                section.property_id,
                data.name,
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Section already exists.",
            )

        section.name = data.name
        section.description = data.description

        return self.section_repo.update(section)

    def delete(
        self,
        current_user,
        section_id,
    ):

        section = self.get(
            current_user,
            section_id,
        )

        self.section_repo.delete(section)