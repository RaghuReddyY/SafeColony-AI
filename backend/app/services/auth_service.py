from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.auth.hashing import hash_password, verify_password
from app.auth.jwt_handler import create_access_token

from app.enums import (
    UserRole,
    UserStatus,
    ResidentStatus,
    OccupancyStatus,
    UnitType,
)

from app.models.user import User
from app.models.unit import Unit
from app.models.resident import Resident

from app.repositories.organization_repository import OrganizationRepository
from app.repositories.user_repository import UserRepository
from app.repositories.section_repository import SectionRepository
from app.repositories.unit_repository import UnitRepository
from app.enums import OccupancyStatus, UnitType


class AuthService:

    def __init__(self, db: Session):

        self.db = db

        self.user_repo = UserRepository(db)
        self.org_repo = OrganizationRepository(db)
        self.section_repo = SectionRepository(db)
        self.unit_repo = UnitRepository(db)

    # ------------------------------------------------------------------
    # Register Resident
    # ------------------------------------------------------------------

    def register(self, data):

        organization = self.org_repo.get_by_code(
            data.organization_code.strip().upper()
        )

        if organization is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid organization code.",
            )

        section = self.section_repo.get_by_id_and_organization(
            data.section_id,
            organization.id,
        )

        if section is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid section.",
            )

        email = data.email.strip().lower()

        if self.user_repo.get_by_email(email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already exists.",
            )

        if self.user_repo.get_by_phone(data.phone):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone already exists.",
            )

        unit_number = data.unit_number.strip().upper()

        unit = self.unit_repo.get_by_section_and_number(
            section.id,
            unit_number,
        )

        if unit is None:

            unit = Unit(
                property_id=section.property_id,
                section_id=section.id,
                unit_number=unit_number,
                unit_type=UnitType.APARTMENT,
                floor=None,
                owner_name=None,
                occupancy_status=OccupancyStatus.VACANT,
                intercom_number=None,
                is_active=True,
            )

            self.unit_repo.create_without_commit(unit)

        user = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            password_hash=hash_password(data.password),
            role=UserRole.RESIDENT.value,
            status=UserStatus.PENDING.value,
            is_active=True,
            organization_id=organization.id,
        )

        self.user_repo.create(
            user=user,
            commit=False,
        )

        resident = Resident(
            user_id=user.id,
            unit_id=unit.id,
            resident_type=data.resident_type,
            status=ResidentStatus.PENDING,
            is_active=True,
        )

        self.db.add(resident)

        self.db.commit()

        self.db.refresh(user)

        return {
            "message": "Registration successful. Awaiting administrator approval.",
            "user_id": user.id,
            "status": user.status,
        }

    # ------------------------------------------------------------------
    # Login
    # ------------------------------------------------------------------

    def login(
        self,
        email: str,
        password: str,
    ):

        email = email.strip().lower()

        user = self.user_repo.get_by_email(email)

        if (
            user is None
            or not user.is_active
            or not verify_password(
                password,
                user.password_hash,
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )

        if user.status == UserStatus.PENDING.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your account is waiting for administrator approval.",
            )

        if user.status == UserStatus.REJECTED.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your registration has been rejected.",
            )

        if user.status == UserStatus.SUSPENDED.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your account has been suspended.",
            )

        token = create_access_token(
            {
                "sub": user.email,
                "user_id": user.id,
                "role": user.role,
                "full_name": user.full_name,
            }
        )

        resident_status = None

        if user.resident:
            resident_status = user.resident.status.value

        return {
            "access_token": token,
            "token_type": "bearer",
            "resident_status": resident_status,
            "user_status": user.status,
        }

    # ------------------------------------------------------------------
    # Change Password
    # ------------------------------------------------------------------

    def change_password(
        self,
        user,
        current_password: str,
        new_password: str,
    ):

        if not verify_password(
            current_password,
            user.password_hash,
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect.",
            )

        user.password_hash = hash_password(
            new_password
        )

        return self.user_repo.update(user)