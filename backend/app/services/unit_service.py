from fastapi import HTTPException, status

from app.models.property import Property
from app.models.section import Section
from app.models.unit import Unit


class UnitService:

    def __init__(self, repo):
        self.repo = repo
        self.db = repo.db

    def create(self, data):
        # Validate Property
        property_obj = (
            self.db.query(Property)
            .filter(Property.id == data.property_id)
            .first()
        )

        if property_obj is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Property with id {data.property_id} not found.",
            )

        # Validate Section
        section_obj = (
            self.db.query(Section)
            .filter(Section.id == data.section_id)
            .first()
        )

        if section_obj is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Section with id {data.section_id} not found.",
            )

        # Validate Section belongs to Property
        if section_obj.property_id != data.property_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Section {data.section_id} "
                    f"does not belong to Property {data.property_id}."
                ),
            )

        # Prevent duplicate unit numbers
        existing = self.repo.get_by_unit_number(
            section_id=data.section_id,
            unit_number=data.unit_number,
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Unit '{data.unit_number}' "
                    "already exists in this section."
                ),
            )

        unit = Unit(
            property_id=data.property_id,
            section_id=data.section_id,
            unit_number=data.unit_number,
            unit_type=data.unit_type,
            floor=data.floor,
            owner_name=data.owner_name,
            intercom_number=data.intercom_number,
        )

        return self.repo.create(unit)

    def get_all(self):
        return self.repo.get_all()

    def get_by_section(self, section_id: int):
        return self.repo.get_by_section(section_id)