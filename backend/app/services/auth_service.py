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
    ResidentType,
)

from app.models.user import User
from app.models.unit import Unit
from app.models.property import Property
from app.models.resident import Resident
from app.models.login_otp import LoginOTP
from app.models.password_reset import PasswordResetToken
from app.models.email_verification import EmailVerificationToken
from app.models.notification import Notification
from app.models.user_block_scope import UserBlockScope
from app.config import settings
from app.services.notification_providers import send_email
from app.core.logger import logger

from app.repositories.organization_repository import OrganizationRepository
from app.repositories.user_repository import UserRepository
from app.repositories.section_repository import SectionRepository
from app.repositories.unit_repository import UnitRepository



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

        organization = None
        if data.organization_code:
            organization = self.org_repo.get_by_code(
                data.organization_code.strip().upper()
            )
            if organization is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invalid organization code.",
                )

        section = None
        if data.section_id is not None and not data.family_join_code:
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
                detail="An account with this email already exists. Please login or use Forgot Password.",
            )

        if self.user_repo.get_by_phone(data.phone):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone already exists.",
            )

        unit = None
        family_sponsor = None

        if data.family_join_code:
            # A family code belongs to a specific sponsor. Owner and tenant
            # sponsors have separate codes so a tenant's family can never be
            # attached to the owner's family relationship by accident.
            code = data.family_join_code.strip().upper()
            unit_query = (
                self.db.query(Unit)
                .join(Property, Unit.property_id == Property.id)
                .filter(
                    Unit.is_active.is_(True),
                    (Unit.family_join_code == code)
                    | (Unit.tenant_family_join_code == code),
                )
            )
            if organization is not None:
                unit_query = unit_query.filter(Property.organization_id == organization.id)
            unit = unit_query.first()
            if unit is not None and organization is None:
                organization = self.org_repo.get_by_id(unit.property.organization_id)
            if unit is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid family join code.")

            if unit.family_join_code == code:
                family_sponsor = (
                    self.db.query(Resident)
                    .filter(
                        Resident.unit_id == unit.id,
                        Resident.resident_type == "OWNER",
                        Resident.is_active.is_(True),
                    )
                    .order_by(Resident.id.asc())
                    .first()
                )
            else:
                family_sponsor = (
                    self.db.query(Resident)
                    .filter(
                        Resident.unit_id == unit.id,
                        Resident.resident_type == "TENANT",
                        Resident.is_active.is_(True),
                    )
                    .order_by(Resident.id.asc())
                    .first()
                )

            if family_sponsor is None:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="This family invitation is no longer valid because its owner/tenant sponsor is not active.",
                )

            # A family member always uses the FAMILY resident type. The
            # sponsor relationship records whether this is an owner's family
            # or a tenant's family.
            resident_type = ResidentType.FAMILY
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

            # A unit may have one owner and one or more tenants, but only one
            # active account can hold each ownership/tenancy role.
            if data.resident_type == ResidentType.OWNER:
                existing_owner = self.db.query(Resident).filter(
                    Resident.unit_id == unit.id,
                    Resident.resident_type == ResidentType.OWNER,
                    Resident.is_active.is_(True),
                ).first()
                if existing_owner:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="This unit already has a registered owner. Use the family invitation code for family members.",
                    )
            elif data.resident_type == ResidentType.TENANT:
                existing_tenant = self.db.query(Resident).filter(
                    Resident.unit_id == unit.id,
                    Resident.resident_type == ResidentType.TENANT,
                    Resident.is_active.is_(True),
                ).first()
                if existing_tenant:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="This unit already has a registered tenant. Use the tenant's family invitation code for family members.",
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Resident type must be Owner, Tenant, or Family via invitation code.",
                )

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
            email_verified=False,
            organization_id=organization.id,
        )

        self.user_repo.create(
            user=user,
            commit=False,
        )

        # The first OWNER/TENANT account for a unit becomes the current
        # maintenance payer. Subsequent owners/tenants are non-payers until
        # the payer is explicitly changed. Family members are never payers.
        make_primary = (
            not data.family_join_code
            and existing_resident_count == 0
            and data.resident_type in {ResidentType.OWNER, ResidentType.TENANT}
        )

        resident = Resident(
            user_id=user.id,
            unit_id=unit.id,
            # For normal owner/tenant registration use the requested resident type.
            # Family registration sets resident_type explicitly above.
            resident_type=(
                ResidentType.FAMILY
                if data.family_join_code
                else data.resident_type
            ),
            family_sponsor_resident_id=family_sponsor.id if family_sponsor else None,
            status=ResidentStatus.PENDING,
            is_primary=make_primary,
            is_active=True,
        )

        self.db.add(resident)
        self.db.flush()

        if make_primary and unit.maintenance_payer_resident_id is None:
            unit.maintenance_payer_resident_id = resident.id

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
                entity_type="RESIDENT_APPROVAL",
                entity_id=resident.id,
                action="OPEN_RESIDENT_APPROVAL",
            ))

        self.db.commit()

        self.db.refresh(user)

        # Email ownership is verified separately from administrator approval.
        # If SMTP is unavailable, keep the account pending and allow resend later.
        if all([
            settings.SMTP_HOST,
            settings.SMTP_USERNAME,
            settings.SMTP_PASSWORD,
            settings.SMTP_FROM_EMAIL,
            settings.EMAIL_VERIFICATION_BASE_URL,
        ]):
            try:
                self._send_email_verification(user)
            except Exception as exc:
                logger.warning("Registration email verification delivery failed: %s", exc)

        return {
            "message": "Registration successful. Please verify your email. After email verification, your registration will remain pending until administrator approval.",
            "user_id": user.id,
            "status": user.status,
        }

    # ------------------------------------------------------------------
    # Email Verification
    # ------------------------------------------------------------------

    def _send_email_verification(self, user: User) -> None:
        if user.email_verified:
            return

        now = datetime.utcnow()
        self.db.query(EmailVerificationToken).filter(
            EmailVerificationToken.user_id == user.id,
            EmailVerificationToken.used_at.is_(None),
        ).update({"used_at": now}, synchronize_session=False)

        raw_token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

        record = EmailVerificationToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=now + timedelta(minutes=settings.EMAIL_VERIFICATION_EXPIRY_MINUTES),
        )
        self.db.add(record)
        self.db.commit()

        base_url = (settings.EMAIL_VERIFICATION_BASE_URL or "").strip().rstrip("/")
        if not base_url:
            record.used_at = datetime.utcnow()
            self.db.commit()
            raise RuntimeError("EMAIL_VERIFICATION_BASE_URL is not configured.")

        verification_url = f"{base_url}/auth/verify-email?token={raw_token}"

        send_email(
            user.email,
            "Verify your SafeColony email",
            (
                f"Hello {user.full_name},\n\n"
                "Welcome to SafeColony. Please verify that this email address belongs to you "
                "by opening the link below:\n\n"
                f"{verification_url}\n\n"
                f"This verification link expires in {settings.EMAIL_VERIFICATION_EXPIRY_MINUTES} minutes "
                "and can be used only once.\n\n"
                "After email verification, your registration will still require administrator approval "
                "before you can log in.\n\n"
                "If you did not create this account, you can safely ignore this email.\n\n"
                "SafeColony"
            ),
        )

    def resend_email_verification(self, email: str) -> dict:
        normalized = email.strip().lower()
        user = self.user_repo.get_by_email(normalized)

        response = {
            "message": "If an account exists and its email is not yet verified, a verification email has been sent."
        }

        if not user or not user.is_active or user.email_verified:
            return response

        # Do not report success when the email provider is unavailable.
        # The Flutter client uses the HTTP status to decide whether the
        # verification email was actually sent.
        missing = []
        if not settings.SMTP_HOST:
            missing.append("SMTP_HOST")
        if not settings.SMTP_USERNAME:
            missing.append("SMTP_USERNAME")
        if not settings.SMTP_PASSWORD:
            missing.append("SMTP_PASSWORD")
        if not settings.SMTP_FROM_EMAIL:
            missing.append("SMTP_FROM_EMAIL")
        if not settings.EMAIL_VERIFICATION_BASE_URL:
            missing.append("EMAIL_VERIFICATION_BASE_URL")

        if missing:
            logger.error(
                "Email verification resend unavailable; missing configuration: %s",
                ", ".join(missing),
            )
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Verification email service is not configured. Please contact the administrator.",
            )

        try:
            self._send_email_verification(user)
        except Exception as exc:
            # Never expose SMTP credentials or provider internals to the
            # mobile client, but make the Cloud Run logs actionable.
            logger.exception(
                "Email verification resend failed for user_id=%s email=%s: %s",
                user.id,
                user.email,
                exc,
            )
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Verification email could not be sent. Please try again later or contact the administrator.",
            ) from exc

        return response

    def verify_email(self, token: str) -> str:
        token_hash = hashlib.sha256(token.strip().encode("utf-8")).hexdigest()
        record = (
            self.db.query(EmailVerificationToken)
            .filter(EmailVerificationToken.token_hash == token_hash)
            .first()
        )
        now = datetime.utcnow()

        if not record or record.used_at is not None or record.expires_at < now:
            return "This verification link is invalid or has expired. Please request a new verification email."

        user = record.user
        if not user or not user.is_active:
            return "This verification link is invalid or has expired."

        user.email_verified = True
        record.used_at = now

        self.db.query(EmailVerificationToken).filter(
            EmailVerificationToken.user_id == user.id,
            EmailVerificationToken.id != record.id,
            EmailVerificationToken.used_at.is_(None),
        ).update({"used_at": now}, synchronize_session=False)

        self.db.commit()
        return "Your email has been verified successfully. You can now return to SafeColony and log in after your account is approved."

    # ------------------------------------------------------------------
    # Forgot / Reset Password
    # ------------------------------------------------------------------

    def forgot_password(self, email: str):
        normalized = email.strip().lower()
        user = self.user_repo.get_by_email(normalized)

        # Always use the same response for unknown addresses to avoid account enumeration.
        response = {
            "message": "If an account exists for this email, password reset instructions have been sent.",
            "expires_in_minutes": settings.PASSWORD_RESET_EXPIRY_MINUTES,
            "dev_reset_token": None,
        }
        if not user or not user.is_active:
            return response

        now = datetime.utcnow()
        self.db.query(PasswordResetToken).filter(
            PasswordResetToken.user_id == user.id,
            PasswordResetToken.used_at.is_(None),
        ).update({"used_at": now}, synchronize_session=False)

        raw_token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
        record = PasswordResetToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=now + timedelta(minutes=settings.PASSWORD_RESET_EXPIRY_MINUTES),
        )
        self.db.add(record)
        self.db.commit()

        if settings.PASSWORD_RESET_DEV_MODE and not settings.is_production:
            response["dev_reset_token"] = raw_token
            return response

        if not all([settings.SMTP_HOST, settings.SMTP_USERNAME, settings.SMTP_PASSWORD, settings.SMTP_FROM_EMAIL]):
            # Keep the response indistinguishable from the unknown-email path.
            # The token is invalidated so an undelivered reset token cannot be reused.
            record.used_at = datetime.utcnow()
            self.db.commit()
            logger.warning("Password reset requested but SMTP is not configured.")
            return response

        try:
            send_email(
                user.email,
                "SafeColony password reset",
                (
                    f"Hello {user.full_name},\n\n"
                    "We received a request to reset your SafeColony password.\n\n"
                    f"Your one-time reset code is:\n\n{raw_token}\n\n"
                    f"This code expires in {settings.PASSWORD_RESET_EXPIRY_MINUTES} minutes and can be used only once.\n\n"
                    "If you did not request this, you can safely ignore this email.\n\n"
                    "SafeColony"
                ),
            )
        except Exception as exc:
            record.used_at = datetime.utcnow()
            self.db.commit()
            logger.warning("Password reset email delivery failed: %s", exc)
            return response

        # Email was delivered successfully. Always return the response expected
        # by ForgotPasswordResponse so FastAPI does not validate a None result.
        return response

    def reset_password(self, email: str, token: str, new_password: str):
        normalized = email.strip().lower()
        token_hash = hashlib.sha256(token.strip().encode("utf-8")).hexdigest()
        record = self.db.query(PasswordResetToken).join(User).filter(
            User.email == normalized,
            PasswordResetToken.token_hash == token_hash,
        ).first()
        if not record or record.used_at is not None or record.expires_at < datetime.utcnow():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="The password reset code is invalid or expired.")

        user = record.user
        if not user or not user.is_active:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="The password reset code is invalid or expired.")

        user.password_hash = hash_password(new_password)
        record.used_at = datetime.utcnow()
        self.db.query(PasswordResetToken).filter(
            PasswordResetToken.user_id == user.id,
            PasswordResetToken.id != record.id,
            PasswordResetToken.used_at.is_(None),
        ).update({"used_at": datetime.utcnow()}, synchronize_session=False)
        self.db.commit()

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

        if not user.email_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Please verify your email address before logging in. Check your Gmail for the SafeColony verification link.",
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
        if not settings.OTP_ENABLED:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mobile OTP login is currently disabled. Please use email and password login.",
            )

        phone = phone.strip()

        user = self.user_repo.get_by_phone(phone)

        if not user or not user.is_active:
            # Do not reveal whether a phone number is registered.
            return {
                "message": "If the mobile number is registered, an OTP has been sent.",
                "expires_in": settings.OTP_EXPIRY_SECONDS,
                "dev_otp": None,
            }

        # --------------------------------------------------------------
        # Production safety:
        # OTP login is optional for production. If no SMS provider is
        # configured, do not generate/store an OTP and do not expose
        # any development OTP.
        # --------------------------------------------------------------
        sms_configured = (
            bool(settings.TWILIO_ACCOUNT_SID)
            and bool(settings.TWILIO_AUTH_TOKEN)
            and bool(settings.TWILIO_FROM_NUMBER)
        )

        if settings.is_production and not sms_configured:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Mobile OTP login is temporarily unavailable. Please use email and password login.",
            )

        code = f"{secrets.randbelow(1_000_000):06d}"
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        now = datetime.utcnow()

        self.db.query(LoginOTP).filter(
            LoginOTP.phone == phone,
            LoginOTP.consumed_at.is_(None),
        ).update(
            {"consumed_at": now},
            synchronize_session=False,
        )

        self.db.add(
            LoginOTP(
                phone=phone,
                code_hash=code_hash,
                expires_at=now + timedelta(
                    seconds=settings.OTP_EXPIRY_SECONDS
                ),
            )
        )

        self.db.commit()

        sent = False

        # --------------------------------------------------------------
        # SMS provider
        # --------------------------------------------------------------
        if sms_configured:
            try:
                url = (
                    "https://api.twilio.com/2010-04-01/"
                    f"Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json"
                )

                body = {
                    "From": settings.TWILIO_FROM_NUMBER,
                    "To": phone,
                    "Body": (
                        f"Your SafeColony login OTP is {code}. "
                        "It expires in 5 minutes."
                    ),
                }

                response = httpx.post(
                    url,
                    data=body,
                    auth=(
                        settings.TWILIO_ACCOUNT_SID,
                        settings.TWILIO_AUTH_TOKEN,
                    ),
                    timeout=10,
                )

                sent = 200 <= response.status_code < 300

            except Exception:
                sent = False

        # --------------------------------------------------------------
        # SMS failed
        # --------------------------------------------------------------
        if not sent and not settings.OTP_DEV_MODE:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "Mobile OTP login is temporarily unavailable. "
                    "Please use email and password login."
                ),
            )

        return {
            "message": "OTP generated successfully.",
            "expires_in": settings.OTP_EXPIRY_SECONDS,
            "dev_otp": code if settings.OTP_DEV_MODE else None,
        }

    def verify_otp(self, phone: str, otp: str):
        if not settings.OTP_ENABLED:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mobile OTP login is currently disabled. Please use email and password login.",
            )

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