import hashlib
import secrets
from datetime import datetime, timedelta
import httpx
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
from app.models.property import Property
from app.models.resident import Resident
from app.models.login_otp import LoginOTP
from app.models.notification import Notification
from app.models.user_block_scope import UserBlockScope
from app.config import settings

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

        section = None
        if data.section_id is not None:
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

        unit = None
        if data.family_join_code:
            unit = (
                self.db.query(Unit)
                .join(Property, Unit.property_id == Property.id)
                .filter(
                    Unit.family_join_code == data.family_join_code.strip().upper(),
                    Unit.is_active.is_(True),
                    Property.organization_id == organization.id,
                )
                .first()
            )
            if unit is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid family join code.")
        else:
            if section is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Property section is required when a family join code is not used.",
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

        existing_resident_count = self.db.query(Resident).filter(
            Resident.unit_id == unit.id,
            Resident.is_active.is_(True),
        ).count()

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
            is_primary=(existing_resident_count == 0),
            is_active=True,
        )

        self.db.add(resident)
        self.db.flush()

        # Notify the administrators who can approve this pending resident.
        # Organization admins see every request; a block admin sees requests
        # only for the block assigned to them. Family members follow the same
        # approval workflow as primary residents.
        admin_users = self.db.query(User).filter(
            User.organization_id == organization.id,
            User.role == UserRole.ORGANIZATION_ADMIN.value,
            User.is_active.is_(True),
        ).all()

        block_admins = []
        if unit.section_id is not None:
            block_admins = (
                self.db.query(User)
                .join(UserBlockScope, UserBlockScope.user_id == User.id)
                .filter(
                    User.organization_id == organization.id,
                    User.role == UserRole.BLOCK_ADMIN.value,
                    User.is_active.is_(True),
                    UserBlockScope.section_id == unit.section_id,
                )
                .all()
            )

        recipients = {u.id: u for u in [*admin_users, *block_admins]}
        resident_type = str(data.resident_type).replace('ResidentType.', '').upper()
        for admin in recipients.values():
            self.db.add(Notification(
                user_id=admin.id,
                title="New Resident Approval Required",
                message=(
                    f"{data.full_name.strip()} submitted a {resident_type.lower().replace('_', ' ')} registration "
                    f"for {organization.name}. Please review and approve the pending resident."
                ),
                notification_type="RESIDENT_APPROVAL",
            ))

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
    # Mobile OTP Login
    # ------------------------------------------------------------------

    def request_otp(self, phone: str):
        phone = phone.strip()
        user = self.user_repo.get_by_phone(phone)
        if not user or not user.is_active:
            # Do not reveal whether a phone number is registered.
            return {
                "message": "If the mobile number is registered, an OTP has been sent.",
                "expires_in": settings.OTP_EXPIRY_SECONDS,
                "dev_otp": None,
            }

        code = f"{secrets.randbelow(1_000_000):06d}"
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        now = datetime.utcnow()
        self.db.query(LoginOTP).filter(
            LoginOTP.phone == phone,
            LoginOTP.consumed_at.is_(None),
        ).update({"consumed_at": now}, synchronize_session=False)
        self.db.add(LoginOTP(
            phone=phone,
            code_hash=code_hash,
            expires_at=now + timedelta(seconds=settings.OTP_EXPIRY_SECONDS),
        ))
        self.db.commit()

        sent = False
        if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_FROM_NUMBER:
            try:
                url = f"https://api.twilio.com/2010-04-01/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json"
                body = {
                    "From": settings.TWILIO_FROM_NUMBER,
                    "To": phone,
                    "Body": f"Your SafeColony login OTP is {code}. It expires in 5 minutes.",
                }
                response = httpx.post(
                    url,
                    data=body,
                    auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN),
                    timeout=10,
                )
                sent = 200 <= response.status_code < 300
            except Exception:
                sent = False

        if not sent and not settings.OTP_DEV_MODE:
            # Never expose the OTP when production SMS delivery is required.
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="OTP delivery is not configured. Configure Twilio SMS and try again.",
            )

        return {
            "message": "OTP generated successfully.",
            "expires_in": settings.OTP_EXPIRY_SECONDS,
            "dev_otp": code if settings.OTP_DEV_MODE else None,
        }

    def verify_otp(self, phone: str, otp: str):
        phone = phone.strip()
        otp = otp.strip()
        user = self.user_repo.get_by_phone(phone)
        if not user or not user.is_active:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid mobile number or OTP.")

        record = (
            self.db.query(LoginOTP)
            .filter(
                LoginOTP.phone == phone,
                LoginOTP.consumed_at.is_(None),
            )
            .order_by(LoginOTP.created_at.desc())
            .first()
        )
        now = datetime.utcnow()
        if not record or record.expires_at < now:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="OTP expired. Please request a new OTP.")
        if record.attempts >= settings.OTP_MAX_ATTEMPTS:
            raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many invalid OTP attempts. Request a new OTP.")

        expected = hashlib.sha256(otp.encode()).hexdigest()
        if not secrets.compare_digest(expected, record.code_hash):
            record.attempts += 1
            self.db.commit()
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid mobile number or OTP.")

        if user.status == UserStatus.PENDING.value:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your account is waiting for administrator approval.")
        if user.status == UserStatus.REJECTED.value:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your registration has been rejected.")
        if user.status == UserStatus.SUSPENDED.value:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your account has been suspended.")

        record.consumed_at = now
        self.db.commit()
        token = create_access_token({
            "sub": user.email,
            "user_id": user.id,
            "role": user.role,
            "full_name": user.full_name,
        })
        resident_status = user.resident.status.value if user.resident else None
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