from sqlalchemy.orm import Session

from app.models.unit import Unit


class UnitRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, unit: Unit) -> Unit:
        self.db.add(unit)
        self.db.commit()
        self.db.refresh(unit)
        return unit

    def get_all(self) -> list[Unit]:
        return self.db.query(Unit).all()

    def get_by_id(self, unit_id: int) -> Unit | None:
        return (
            self.db.query(Unit)
            .filter(Unit.id == unit_id)
            .first()
        )

    def get_by_section(self, section_id: int) -> list[Unit]:
        return (
            self.db.query(Unit)
            .filter(Unit.section_id == section_id)
            .all()
        )

    def get_by_unit_number(
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