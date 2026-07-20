from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.resident import Resident
from app.models.unit import Unit
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor


class ResidentRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, resident: Resident) -> Resident:
        self.db.add(resident)
        self.db.commit()
        self.db.refresh(resident)
        return resident

    def update(self, resident: Resident) -> Resident:
        self.db.commit()
        self.db.refresh(resident)
        return resident

    def get_all(self) -> list[Resident]:
        return self.db.query(Resident).all()

    def get_by_id(self, resident_id: int) -> Resident | None:
        return (
            self.db.query(Resident)
            .filter(Resident.id == resident_id)
            .first()
        )

    def get_by_unit(self, unit_id: int) -> list[Resident]:
        return (
            self.db.query(Resident)
            .filter(Resident.unit_id == unit_id)
            .all()
        )

    def get_by_phone(self, phone: str) -> Resident | None:
        return (
            self.db.query(Resident)
            .filter(Resident.phone == phone)
            .first()
        )

    def get_by_email(self, email: str) -> Resident | None:
        return (
            self.db.query(Resident)
            .filter(Resident.email == email)
            .first()
        )

    def get_primary_by_unit(self, unit_id: int) -> Resident | None:
        return (
            self.db.query(Resident)
            .filter(
                Resident.unit_id == unit_id,
                Resident.is_primary.is_(True),
            )
            .first()
        )

    def unit_exists(self, unit_id: int) -> bool:
        return (
            self.db.query(Unit)
            .filter(Unit.id == unit_id)
            .first()
            is not None
        )

    def get_profile(self, resident_id: int) -> Resident | None:
        return self.get_by_id(resident_id)

    def get_dropdown(self) -> list[Resident]:
        return (
            self.db.query(Resident)
            .order_by(Resident.full_name.asc())
            .all()
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
                Notification.is_read.is_(False),
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