from fastapi import HTTPException, status

from app.models.property import Property
from app.models.section import Section
from app.models.unit import Unit
from app.enums import OccupancyStatus



class UnitService:

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


        if not property_obj:
            raise HTTPException(
                status_code=404,
                detail="Property not found.",
            )


        section_obj = (
            self.db.query(Section)
            .filter(
                Section.id == data.section_id
            )
            .first()
        )


        if not section_obj:
            raise HTTPException(
                status_code=404,
                detail="Section not found.",
            )


        if section_obj.property_id != data.property_id:

            raise HTTPException(
                status_code=409,
                detail="Section does not belong to property.",
            )


        if self.repo.exists(
            data.section_id,
            data.unit_number,
        ):

            raise HTTPException(
                status_code=409,
                detail="Unit already exists.",
            )


        unit = Unit(

            property_id=data.property_id,

            section_id=data.section_id,

            unit_number=data.unit_number,

            unit_type=data.unit_type,

            floor=data.floor,

            owner_name=data.owner_name,

            intercom_number=data.intercom_number,

            occupancy_status=OccupancyStatus.VACANT,
        )


        return self.repo.create(unit)



    def get_all(self):

        return self.repo.get_all()



    def get(self, unit_id:int):

        unit = self.repo.get_by_id(unit_id)

        if not unit:
            raise HTTPException(
                status_code=404,
                detail="Unit not found.",
            )

        return unit



    def get_by_section(
        self,
        section_id:int,
    ):

        return self.repo.get_by_section(
            section_id
        )



    def get_by_property(
        self,
        property_id:int,
    ):

        return self.repo.get_by_property(
            property_id
        )



    def update(
        self,
        unit_id,
        data,
    ):

        unit = self.get(unit_id)


        if data.unit_number:

            unit.unit_number = data.unit_number


        if data.unit_type:

            unit.unit_type = data.unit_type


        if data.floor:

            unit.floor = data.floor


        if data.owner_name:

            unit.owner_name = data.owner_name


        if data.intercom_number:

            unit.intercom_number = data.intercom_number


        return self.repo.update(unit)



    def delete(
        self,
        unit_id:int,
    ):

        unit = self.get(unit_id)

        self.repo.delete(unit)