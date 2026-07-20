from fastapi import HTTPException, status

from app.models.property import Property
from app.models.section import Section


class SectionService:

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

        # Prevent duplicate section names
        existing = self.repo.get_by_name(
            property_id=data.property_id,
            name=data.name,
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Section '{data.name}' already exists for this property.",
            )

        section = Section(
            property_id=data.property_id,
            name=data.name,
            description=data.description,
        )

        return self.repo.create(section)

    def get_all(self):
        return self.repo.get_all()

    def get_by_property(self, property_id: int):
        return self.repo.get_by_property(property_id)