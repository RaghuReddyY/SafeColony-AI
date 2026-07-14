from sqlalchemy.orm import Session

from app.models.resident import Resident


class ResidentRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, resident: Resident):
        self.db.add(resident)
        self.db.commit()
        self.db.refresh(resident)
        return resident

    def get_all(self):
        return self.db.query(Resident).all()

    def get_by_unit(self, unit_id: int):
        return (
            self.db.query(Resident)
            .filter(Resident.unit_id == unit_id)
            .all()
        )

    def get_by_phone(self, phone: str):
        return (
            self.db.query(Resident)
            .filter(Resident.phone == phone)
            .first()
        )