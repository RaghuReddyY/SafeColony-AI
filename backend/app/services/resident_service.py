from sqlalchemy.orm import Session

from app.enums import ResidentStatus, UserStatus
from app.models.resident import Resident
from app.models.user import User

from app.repositories.resident_repository import ResidentRepository
from app.repositories.unit_repository import UnitRepository
from app.repositories.user_repository import UserRepository


class ResidentService:

    def __init__(self, db: Session):

        self.db = db
        self.resident_repo = ResidentRepository(db)
        self.user_repo = UserRepository(db)
        self.unit_repo = UnitRepository(db)

    # --------------------------------------------------
    # Resident List
    # --------------------------------------------------

    def get_all(
        self,
        current_user: User,
    ):

        return self.resident_repo.get_all_by_organization(
            current_user.organization_id,
        )

    def get_pending(
        self,
        current_user: User,
    ):

        return self.resident_repo.get_pending_by_organization(
            current_user.organization_id,
        )

    def get_by_id(
        self,
        resident_id: int,
        current_user: User,
    ):

        return self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

    def get_profile(
        self,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_user_id(
            current_user.id,
        )

        if resident is None:
            raise ValueError("Resident profile not found.")

        return resident

    # --------------------------------------------------
    # Dashboard
    # --------------------------------------------------

    def get_dashboard(
        self,
        current_user: User,
    ):

        dashboard = self.resident_repo.get_dashboard_by_user(
            current_user.id,
        )

        if dashboard is None:
            raise ValueError("Resident profile not found.")

        return dashboard

    # --------------------------------------------------
    # Create
    # --------------------------------------------------

    def create(
        self,
        *,
        user_id: int,
        unit_id: int | None,
        resident_type,
        gender,
        date_of_birth,
        emergency_contact,
        emergency_contact_name,
        is_primary,
        current_user: User,
    ):

        user = self.user_repo.get_by_id(user_id)

        if user is None:
            raise ValueError("User not found.")

        if (
            user.organization_id
            != current_user.organization_id
        ):
            raise ValueError(
                "User belongs to another organization."
            )

        if unit_id is not None:

            unit = self.unit_repo.get_by_id_and_organization(
                unit_id,
                current_user.organization_id,
            )

            if unit is None:
                raise ValueError(
                    "Unit not found."
                )

        resident = Resident(
            user_id=user_id,
            unit_id=unit_id,
            resident_type=resident_type,
            gender=gender,
            date_of_birth=date_of_birth,
            emergency_contact=emergency_contact,
            emergency_contact_name=emergency_contact_name,
            is_primary=is_primary,
            status=ResidentStatus.PENDING,
            is_active=True,
        )

        return self.resident_repo.create(
            resident,
        )
        # --------------------------------------------------
    # Update
    # --------------------------------------------------

    def update(
        self,
        resident_id: int,
        *,
        unit_id: int | None,
        resident_type,
        gender,
        date_of_birth,
        emergency_contact,
        emergency_contact_name,
        is_primary,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        if unit_id is not None:

            unit = self.unit_repo.get_by_id_and_organization(
                unit_id,
                current_user.organization_id,
            )

            if unit is None:
                raise ValueError("Unit not found.")

        resident.unit_id = unit_id
        resident.resident_type = resident_type
        resident.gender = gender
        resident.date_of_birth = date_of_birth
        resident.emergency_contact = emergency_contact
        resident.emergency_contact_name = emergency_contact_name
        resident.is_primary = is_primary

        return self.resident_repo.update(resident)

    # --------------------------------------------------
    # Approval
    # --------------------------------------------------

    def approve(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        return self.resident_repo.approve(resident)

    def reject(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        return self.resident_repo.reject(resident)

    # --------------------------------------------------
    # Activate / Deactivate
    # --------------------------------------------------

    def activate(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        resident.is_active = True

        if resident.user:
            resident.user.is_active = True

        return self.resident_repo.update(resident)

    def deactivate(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        resident.is_active = False

        if resident.user:
            resident.user.is_active = False

        return self.resident_repo.update(resident)

    # --------------------------------------------------
    # Delete
    # --------------------------------------------------

    def delete(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(
            resident_id,
            current_user.organization_id,
        )

        if resident is None:
            raise ValueError("Resident not found.")

        self.db.delete(resident)
        self.db.commit()

        return {
            "message": "Resident deleted successfully."
        }