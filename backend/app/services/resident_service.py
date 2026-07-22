from fastapi import HTTPException, status
from app.core.exceptions import NotFoundException
from app.enums import ResidentStatus
from app.models.unit import Unit
from app.models.user import User
from app.enums import ResidentStatus, UserStatus
from app.schemas.resident import (
    ResidentProfileResponse,
    ResidentResponse,
)

class ResidentService:

    def __init__(self, repo):
        self.repo = repo
        self.db = repo.db

    # --------------------------------------------------
    # Create Resident (Admin)
    # --------------------------------------------------

    def create(self, data):

        unit = (
            self.db.query(Unit)
            .filter(Unit.id == data.unit_id)
            .first()
        )

        if unit is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Unit with id {data.unit_id} not found.",
            )

        resident = self.repo.get_by_user_id(data.user_id)

        if resident is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resident profile not found for this user.",
            )

        if resident.unit_id is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Resident is already assigned to a unit.",
            )

        if data.is_primary:
            primary = self.repo.get_primary_by_unit(
                data.unit_id,
            )

            if primary:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Primary resident already exists for this unit.",
                )

        resident.unit_id = data.unit_id
        resident.resident_type = data.resident_type
        resident.gender = data.gender
        resident.date_of_birth = data.date_of_birth
        resident.emergency_contact = data.emergency_contact
        resident.emergency_contact_name = (
            data.emergency_contact_name
        )
        resident.is_primary = data.is_primary
        resident.status = ResidentStatus.ACTIVE

        resident = self.repo.update(resident)

        if unit.occupancy_status == "VACANT":
            unit.occupancy_status = "OCCUPIED"
            self.db.commit()

        return ResidentResponse(
            id=resident.id,
            user_id=resident.user_id,
            unit_id=resident.unit_id,
            full_name=resident.user.full_name,
            email=resident.user.email,
            phone=resident.user.phone,
            resident_type=resident.resident_type.value
            if hasattr(resident.resident_type, "value")
            else resident.resident_type,
            status=resident.status.value
            if hasattr(resident.status, "value")
            else resident.status,
            gender=resident.gender,
            is_primary=resident.is_primary,
            is_active=resident.is_active,
        )

    # --------------------------------------------------
    # Residents
    # --------------------------------------------------

    def get_all(self):
        return self.repo.get_all()

    def get_by_unit(self, unit_id: int):
        return self.repo.get_by_unit(unit_id)

    # --------------------------------------------------
    # Dashboard
    # --------------------------------------------------

    def dashboard(self, user_id: int):

        data = self.repo.get_dashboard_by_user(user_id)

        if data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resident profile not found. Please join an organization.",
            )

        resident = data["resident"]

        if resident.status != ResidentStatus.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Resident approval pending.",
            )

        return {
            "resident_name": resident.user.full_name,
            "unit_number": (
                resident.unit.unit_number
                if resident.unit
                else "Not Assigned"
            ),
            "vehicles": data["vehicles"],
            "pending_visitors": data["pending"],
            "approved_visitors": data["approved"],
            "inside_visitors": data["inside"],
            "notifications": data["notifications"],
        }

    # --------------------------------------------------
    # Profile
    # --------------------------------------------------

    def get_profile(self, resident_id: int):

        resident = self.repo.get_profile(
            resident_id
        )

        if resident is None:
            raise NotFoundException("Resident")

        return ResidentProfileResponse(
            id=resident.id,
            user_id=resident.user_id,
            full_name=resident.user.full_name,
            email=resident.user.email,
            phone=resident.user.phone,
            resident_type=resident.resident_type.value
            if hasattr(resident.resident_type, "value")
            else resident.resident_type,
            status=resident.status.value
            if hasattr(resident.status, "value")
            else resident.status,
            gender=resident.gender,
            date_of_birth=resident.date_of_birth,
            emergency_contact=resident.emergency_contact,
            emergency_contact_name=resident.emergency_contact_name,
            unit_id=resident.unit_id,
        )

    def update_profile(
        self,
        resident_id: int,
        data,
    ):

        resident = self.repo.get_profile(
            resident_id,
        )

        if resident is None:
            raise NotFoundException("Resident")

        user = resident.user

        if (
            data.email
            and data.email != user.email
        ):

            existing = (
                self.db.query(User)
                .filter(User.email == data.email)
                .first()
            )

            if existing and existing.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already exists.",
                )

        if (
            data.phone
            and data.phone != user.phone
        ):

            existing = (
                self.db.query(User)
                .filter(User.phone == data.phone)
                .first()
            )

            if existing and existing.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Phone number already exists.",
                )

        user.full_name = data.full_name
        user.email = data.email
        user.phone = data.phone

        resident.gender = data.gender
        resident.date_of_birth = data.date_of_birth
        resident.emergency_contact = (
            data.emergency_contact
        )
        resident.emergency_contact_name = (
            data.emergency_contact_name
        )

        self.db.commit()
        self.db.refresh(resident)

        return ResidentProfileResponse(
            id=resident.id,
            user_id=resident.user_id,
            full_name=resident.user.full_name,
            email=resident.user.email,
            phone=resident.user.phone,
            resident_type=resident.resident_type.value
            if hasattr(resident.resident_type, "value")
            else resident.resident_type,
            status=resident.status.value
            if hasattr(resident.status, "value")
            else resident.status,
            gender=resident.gender,
            date_of_birth=resident.date_of_birth,
            emergency_contact=resident.emergency_contact,
            emergency_contact_name=resident.emergency_contact_name,
            unit_id=resident.unit_id,
        )

    # --------------------------------------------------
    # Dropdown
    # --------------------------------------------------

    def dropdown(self):

        residents = self.repo.get_dropdown()

        return [
            {
                "id": resident.id,
                "name": resident.user.full_name,
                "flat": (
                    resident.unit.unit_number
                    if resident.unit
                    else ""
                ),
            }
            for resident in residents
        ]

    # --------------------------------------------------
    # Pending Approval
    # --------------------------------------------------

    def get_pending(self):

        residents = self.repo.get_pending()

        return [
            ResidentResponse(
                id=resident.id,
                user_id=resident.user_id,
                unit_id=resident.unit_id,
                full_name=resident.user.full_name,
                email=resident.user.email,
                phone=resident.user.phone,
                resident_type=resident.resident_type.value
                if hasattr(resident.resident_type, "value")
                else resident.resident_type,
                status=resident.status.value
                if hasattr(resident.status, "value")
                else resident.status,
                gender=resident.gender,
                is_primary=resident.is_primary,
                is_active=resident.is_active,
            )
            for resident in residents
        ]

    def approve(self, resident_id: int):

        resident = self.repo.get_by_id(
            resident_id,
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        resident = self.repo.approve(resident)

        if resident.unit is not None:
            resident.unit.occupancy_status = "OCCUPIED"
            self.db.commit()

        return ResidentResponse(
            id=resident.id,
            user_id=resident.user_id,
            unit_id=resident.unit_id,
            full_name=resident.user.full_name,
            email=resident.user.email,
            phone=resident.user.phone,
            resident_type=resident.resident_type.value
            if hasattr(resident.resident_type, "value")
            else resident.resident_type,
            status=resident.status.value
            if hasattr(resident.status, "value")
            else resident.status,
            gender=resident.gender,
            is_primary=resident.is_primary,
            is_active=resident.is_active,
        )

    def reject(self, resident_id: int):

        resident = self.repo.get_by_id(
            resident_id,
        )

        if resident is None:
            raise NotFoundException(
                "Resident"
            )

        resident = self.repo.reject(resident)

        return ResidentResponse(
            id=resident.id,
            user_id=resident.user_id,
            unit_id=resident.unit_id,
            full_name=resident.user.full_name,
            email=resident.user.email,
            phone=resident.user.phone,
            resident_type=resident.resident_type.value
            if hasattr(resident.resident_type, "value")
            else resident.resident_type,
            status=resident.status.value
            if hasattr(resident.status, "value")
            else resident.status,
            gender=resident.gender,
            is_primary=resident.is_primary,
            is_active=resident.is_active,
        )