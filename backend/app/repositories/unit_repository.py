from sqlalchemy.orm import Session

from app.models.unit import Unit
from app.models.property import Property


class UnitRepository:

    def __init__(self, db: Session):
        self.db = db


    def create(
        self,
        unit: Unit,
    ) -> Unit:

        self.db.add(unit)
        self.db.commit()
        self.db.refresh(unit)

        return unit


    def get_all(
        self,
    ) -> list[Unit]:

        return (
            self.db.query(Unit)
            .all()
        )


    def get_by_id(
        self,
        unit_id: int,
    ) -> Unit | None:

        return (
            self.db.query(Unit)
            .filter(
                Unit.id == unit_id
            )
            .first()
        )


    def get_by_section(
        self,
        section_id: int,
    ) -> list[Unit]:

        return (
            self.db.query(Unit)
            .filter(
                Unit.section_id == section_id
            )
            .all()
        )


    def get_by_property(
        self,
        property_id: int,
    ) -> list[Unit]:

        return (
            self.db.query(Unit)
            .filter(
                Unit.property_id == property_id
            )
            .all()
        )


    def exists(
        self,
        section_id: int,
        unit_number: str,
    ) -> bool:

        return (
            self.db.query(Unit)
            .filter(
                Unit.section_id == section_id,
                Unit.unit_number == unit_number,
            )
            .first()
            is not None
        )


    def update(
        self,
        unit: Unit,
    ) -> Unit:

        self.db.commit()
        self.db.refresh(unit)

        return unit


    def delete(
        self,
        unit: Unit,
    ):

        self.db.delete(unit)
        self.db.commit()


    def get_by_id_and_organization(
        self,
        unit_id: int,
        organization_id: int,
    ) -> Unit | None:

        return (
            self.db.query(Unit)
            .join(
                Property,
                Unit.property_id == Property.id,
            )
            .filter(
                Unit.id == unit_id,
                Property.organization_id == organization_id,
            )
            .first()
        )
    
    def get_all_by_organization(
        self,
        organization_id: int,
    ) -> list[Unit]:

        return (
            self.db.query(Unit)
            .join(
                Property,
                Unit.property_id == Property.id,
            )
            .filter(
                Property.organization_id == organization_id,
            )
            .all()
        )
    
    def get_by_section_and_number(
        self,
        section_id: int,
        unit_number: str,
    ) -> Unit | None:

        return (
            self.db.query(Unit)
            .filter(
                Unit.section_id == section_id,
                Unit.unit_number == unit_number,
            )
            .first()
        )


    def create_without_commit(
        self,
        unit: Unit,
    ) -> Unit:

        self.db.add(unit)
        self.db.flush()

        return unit