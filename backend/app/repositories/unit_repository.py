from sqlalchemy.orm import Session

from app.models.unit import Unit


class UnitRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, unit: Unit):
        self.db.add(unit)
        self.db.commit()
        self.db.refresh(unit)
        return unit

    def get_all(self):
        return self.db.query(Unit).all()

    def get_by_section(self, section_id: int):
        return (
            self.db.query(Unit)
            .filter(Unit.section_id == section_id)
            .all()
        )