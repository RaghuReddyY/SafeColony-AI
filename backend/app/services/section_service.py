from fastapi import HTTPException, status

from app.models.property import Property
from app.models.section import Section


class SectionService:

    def __init__(self, repo):

        self.repo = repo
        self.db = repo.db


    def create(self, data):

        property_obj = (
            self.db.query(Property)
            .filter(
                Property.id == data.property_id
            )
            .first()
        )

        if property_obj is None:
            raise HTTPException(
                status_code=404,
                detail="Property not found.",
            )


        if self.repo.exists_by_name(
            data.property_id,
            data.name,
        ):
            raise HTTPException(
                status_code=409,
                detail="Section already exists.",
            )


        section = Section(
            property_id=data.property_id,
            name=data.name,
            description=data.description,
        )

        return self.repo.create(section)


    def get_all(self):

        return self.repo.get_all()


    def get_by_property(
        self,
        property_id:int,
    ):

        return self.repo.get_by_property(
            property_id
        )


    def get(
        self,
        section_id:int,
    ):

        section = self.repo.get_by_id(
            section_id
        )

        if not section:
            raise HTTPException(
                status_code=404,
                detail="Section not found.",
            )

        return section


    def update(
        self,
        section_id,
        data,
    ):

        section = self.get(section_id)


        if (
            section.name.lower()
            != data.name.lower()
            and self.repo.exists_by_name(
                section.property_id,
                data.name,
            )
        ):
            raise HTTPException(
                status_code=409,
                detail="Section already exists.",
            )


        section.name = data.name
        section.description = data.description


        return self.repo.update(section)



    def delete(
        self,
        section_id:int,
    ):

        section = self.get(section_id)

        self.repo.delete(section)