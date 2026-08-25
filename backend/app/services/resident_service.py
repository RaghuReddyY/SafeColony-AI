from sqlalchemy.orm import Session

from app.enums import ResidentStatus, UserStatus
from app.models.resident import Resident
from app.models.user import User

from app.repositories.resident_repository import ResidentRepository
from app.repositories.unit_repository import UnitRepository
from app.repositories.user_repository import UserRepository
from app.services.scope_service import ScopeService


class ResidentService:

    def __init__(self, db: Session):

        self.db = db
        self.resident_repo = ResidentRepository(db)
        self.user_repo = UserRepository(db)
        self.unit_repo = UnitRepository(db)

    def _check_scope(self, current_user, resident):
        if current_user.role != "BLOCK_ADMIN":
            return
        section_ids = set(ScopeService.block_ids(self.db, current_user))
        if not resident.unit or resident.unit.section_id not in section_ids:
            raise ValueError("Resident is outside your assigned block.")

    # --------------------------------------------------
    # Resident List
    # --------------------------------------------------

    def get_all(
        self,
        current_user: User,
    ):

        residents = self.resident_repo.get_all_by_organization(current_user.organization_id)
        if current_user.role == "BLOCK_ADMIN":
            ids = set(ScopeService.block_ids(self.db, current_user))
            return [r for r in residents if r.unit and r.unit.section_id in ids]
        return residents

    def get_pending(
        self,
        current_user: User,
    ):

        residents = self.resident_repo.get_pending_by_organization(current_user.organization_id)
        if current_user.role == "BLOCK_ADMIN":
            ids = set(ScopeService.block_ids(self.db, current_user))
            return [r for r in residents if r.unit and r.unit.section_id in ids]
        return residents

    def get_by_id(
        self,
        resident_id: int,
        current_user: User,
    ):

        resident = self.resident_repo.get_by_id_and_organization(resident_id, current_user.organization_id)
        if resident is not None:
            self._check_scope(current_user, resident)
        return resident

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
            if current_user.role == "BLOCK_ADMIN" and unit.section_id not in set(ScopeService.block_ids(self.db, current_user)):
                raise ValueError("Unit is outside your assigned block.")

        if is_primary and unit_id is not None and resident_type in {"OWNER", "TENANT"}:
            self.db.query(Resident).filter(
                Resident.unit_id == unit_id,
                Resident.is_primary.is_(True),
            ).update({"is_primary": False}, synchronize_session=False)

        resident = Resident(
            user_id=user_id,
            unit_id=unit_id,
            resident_type=resident_type,
            gender=gender,
            date_of_birth=date_of_birth,
            emergency_contact=emergency_contact,
            emergency_contact_name=emergency_contact_name,
            is_primary=bool(is_primary and resident_type in {"OWNER", "TENANT"}),
            status=ResidentStatus.PENDING,
            is_active=True,
        )

        result = self.resident_repo.create(resident)
        if result.is_primary and result.unit:
            result.unit.maintenance_payer_resident_id = result.id
            self.db.commit()
            self.db.refresh(result)
        return result
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
        self._check_scope(current_user, resident)

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
        resident.is_primary = bool(is_primary and resident.resident_type in {"OWNER", "TENANT"})

        if resident.is_primary and resident.unit_id:
            self.db.query(Resident).filter(
                Resident.unit_id == resident.unit_id,
                Resident.id != resident.id,
                Resident.is_primary.is_(True),
            ).update({"is_primary": False}, synchronize_session=False)
            resident.unit.maintenance_payer_resident_id = resident.id

        result = self.resident_repo.update(resident)
        return result

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
        self._check_scope(current_user, resident)

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
        self._check_scope(current_user, resident)

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
        self._check_scope(current_user, resident)

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
        self._check_scope(current_user, resident)

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
        self._check_scope(current_user, resident)

        self.db.delete(resident)
        self.db.commit()

        return {
            "message": "Resident deleted successfully."
        }