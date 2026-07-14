from datetime import date

from sqlalchemy.orm import Session

from app.models.vacation_mode import VacationMode
from sqlalchemy import func


class VacationRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, vacation: VacationMode):
        self.db.add(vacation)
        self.db.commit()
        self.db.refresh(vacation)
        return vacation

    def get_active(self, resident_id: int):

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == "ACTIVE",
            )
            .first()
        )

    def get_by_resident(self, resident_id: int):

        return (
            self.db.query(VacationMode)
            .filter(VacationMode.resident_id == resident_id)
            .order_by(VacationMode.created_at.desc())
            .all()
        )

    def get_by_id(self, vacation_id: int):

        return (
            self.db.query(VacationMode)
            .filter(VacationMode.id == vacation_id)
            .first()
        )

    def is_resident_on_vacation(self, resident_id: int):

        today = date.today()

        return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == "ACTIVE",
                VacationMode.start_date <= today,
                VacationMode.end_date >= today,
            )
            .first()
        )

    def save(self, vacation):

        self.db.commit()
        self.db.refresh(vacation)

        return vacation
    
    def get_active_vacations(self):

            today = date.today()

            return (
            self.db.query(VacationMode)
            .filter(
                VacationMode.status == "ACTIVE",
                VacationMode.start_date <= today,
                VacationMode.end_date >= today,
            )
            .all()
        )