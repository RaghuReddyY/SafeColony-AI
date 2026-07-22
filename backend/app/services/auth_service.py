from fastapi import HTTPException, status

from app.auth.hashing import hash_password, verify_password
from app.auth.jwt_handler import create_access_token

from app.enums import UserRole, UserStatus


class AuthService:

    def __init__(self, repo):
        self.repo = repo

    # ------------------------------------------------------------------
    # Register Resident
    # ------------------------------------------------------------------

    def register(self, data):

        email = data.email.strip().lower()

        if self.repo.get_by_email(email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already exists.",
            )

        if self.repo.get_by_phone(data.phone):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone already exists.",
            )

        from app.models.user import User

        user = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            password_hash=hash_password(data.password),
            role=UserRole.RESIDENT.value,
            status=UserStatus.PENDING.value,
            is_active=True,
        )

        self.repo.create(user)

        return {
            "message": "Registration successful. Your account is pending approval.",
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

        user = self.repo.get_by_email(email)

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

        # --------------------------------------------------------------
        # User approval status validation
        # --------------------------------------------------------------

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

        return self.repo.update(user)