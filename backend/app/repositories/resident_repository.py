from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.enums import ResidentStatus, UserStatus
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.unit import Unit
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor


class ResidentRepository:

    def __init__(self, db: Session):
        self.db = db

    # --------------------------------------------------
    # Common Load Options
    # --------------------------------------------------

    def _load_options(self):
        return (
            joinedload(Resident.user),
            joinedload(Resident.unit).joinedload(Unit.section),
            joinedload(Resident.unit).joinedload(Unit.property),
        )

    # --------------------------------------------------
    # CRUD
    # --------------------------------------------------

    def create(
        self,
        resident: Resident,
    ) -> Resident:

        self.db.add(resident)
        self.db.commit()
        self.db.refresh(resident)

        return resident

    def update(
        self,
        resident: Resident,
    ) -> Resident:

        self.db.commit()
        self.db.refresh(resident)

        return resident

    # --------------------------------------------------
    # Organization Scoped Queries
    # --------------------------------------------------

    def get_all_by_organization(
        self,
        organization_id: int,
    ) -> list[Resident]:

        return (
            self.db.query(Resident)
            .join(User)
            .options(*self._load_options())
            .filter(
                User.organization_id == organization_id,
            )
            .order_by(User.full_name.asc())
            .all()
        )

    def get_by_id_and_organization(
        self,
        resident_id: int,
        organization_id: int,
    ) -> Resident | None:

        return (
            self.db.query(Resident)
            .join(User)
            .options(*self._load_options())
            .filter(
                Resident.id == resident_id,
                User.organization_id == organization_id,
            )
            .first()
        )

    def get_by_unit_and_organization(
        self,
        unit_id: int,
        organization_id: int,
    ) -> list[Resident]:

        return (
            self.db.query(Resident)
            .join(User)
            .options(*self._load_options())
            .filter(
                Resident.unit_id == unit_id,
                User.organization_id == organization_id,
            )
            .order_by(User.full_name.asc())
            .all()
        )

    def get_pending_by_organization(
        self,
        organization_id: int,
    ) -> list[Resident]:

        return (
            self.db.query(Resident)
            .join(User)
            .options(*self._load_options())
            .filter(
                User.organization_id == organization_id,
                Resident.status == ResidentStatus.PENDING,
            )
            .order_by(User.full_name.asc())
            .all()
        )

    def get_dropdown_by_organization(
        self,
        organization_id: int,
    ) -> list[Resident]:

        return (
            self.db.query(Resident)
            .join(User)
            .options(*self._load_options())
            .filter(
                User.organization_id == organization_id,
                Resident.is_active.is_(True),
            )
            .order_by(User.full_name.asc())
            .all()
        )

    # --------------------------------------------------
    # Generic Queries
    # --------------------------------------------------

    def get_by_user_id(
        self,
        user_id: int,
    ) -> Resident | None:

        return (
            self.db.query(Resident)
            .options(*self._load_options())
            .filter(
                Resident.user_id == user_id,
            )
            .first()
        )

    def get_profile(
        self,
        resident_id: int,
    ) -> Resident | None:

        return self.get_by_id(resident_id)

    def get_by_id(
        self,
        resident_id: int,
    ) -> Resident | None:

        return (
            self.db.query(Resident)
            .options(*self._load_options())
            .filter(
                Resident.id == resident_id,
            )
            .first()
        )

    def get_primary_by_unit(
        self,
        unit_id: int,
    ) -> Resident | None:

        return (
            self.db.query(Resident)
            .filter(
                Resident.unit_id == unit_id,
                Resident.is_primary.is_(True),
            )
            .first()
        )
        # --------------------------------------------------
    # Dashboard
    # --------------------------------------------------

    def get_dashboard_by_user(
        self,
        user_id: int,
    ):

        resident = self.get_by_user_id(user_id)

        if resident is None:
            return None

        resident_id = resident.id

        vehicles = (
            self.db.query(func.count(Vehicle.id))
            .filter(
                Vehicle.resident_id == resident_id
            )
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
            "resident_name": resident.full_name,
            "unit_number": (
                resident.unit.unit_number
                if resident.unit
                else ""
            ),
            "vehicles": vehicles,
            "pending_visitors": pending,
            "approved_visitors": approved,
            "inside_visitors": inside,
            "notifications": notifications,
        }

    # --------------------------------------------------
    # Validation Helpers
    # --------------------------------------------------

    def unit_exists(
        self,
        unit_id: int,
    ) -> bool:

        return (
            self.db.query(Unit)
            .filter(
                Unit.id == unit_id
            )
            .first()
            is not None
        )

    # --------------------------------------------------
    # Approval
    # --------------------------------------------------

    def approve(
        self,
        resident: Resident,
    ) -> Resident:

        resident.status = ResidentStatus.ACTIVE

        if resident.user:
            resident.user.status = UserStatus.ACTIVE.value

        self.db.commit()
        self.db.refresh(resident)

        return resident

    def reject(
        self,
        resident: Resident,
    ) -> Resident:

        resident.status = ResidentStatus.REJECTED

        if resident.user:
            resident.user.status = UserStatus.REJECTED.value

        self.db.commit()
        self.db.refresh(resident)

        return resident