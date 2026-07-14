from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.resident import Resident
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor


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

    def get_by_id(self, resident_id: int):
        return (
            self.db.query(Resident)
            .filter(Resident.id == resident_id)
            .first()
        )

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

    def get_dashboard(self, resident_id: int):

        resident = self.get_by_id(resident_id)

        if resident is None:
            return None

        vehicles = (
            self.db.query(func.count(Vehicle.id))
            .filter(Vehicle.resident_id == resident_id)
            .scalar()
        )

        pending = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "PENDING",
            )
            .scalar()
        )

        approved = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "APPROVED",
            )
            .scalar()
        )

        inside = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "CHECKED_IN",
            )
            .scalar()
        )

        notifications = (
            self.db.query(func.count(Notification.id))
            .filter(
                Notification.resident_id == resident_id,
                Notification.is_read == False,
            )
            .scalar()
        )

        return {
            "resident": resident,
            "vehicles": vehicles,
            "pending": pending,
            "approved": approved,
            "inside": inside,
            "notifications": notifications,
        }
    
    def update(self, resident: Resident):

        self.db.commit()
        self.db.refresh(resident)

        return resident
    
    def get_profile(self, resident_id: int):

     return (
        self.db.query(Resident)
        .filter(Resident.id == resident_id)
        .first()
    )