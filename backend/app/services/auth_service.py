from fastapi import HTTPException, status

from app.auth.hashing import hash_password, verify_password
from app.auth.jwt_handler import create_access_token
from app.models.user import User
from app.enums import UserRole

class AuthService:

    def __init__(self, repo):
        self.repo = repo

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
                detail="Phone number already exists.",
            )

        user = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            password_hash=hash_password(data.password),
            role=UserRole.RESIDENT,
            is_active=True,
        )

        return self.repo.create(user)

    def login(self, email: str, password: str):

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

        token = create_access_token(
            {
                "sub": user.email,
                "user_id": user.id,
                "role": user.role.value,
                "full_name": user.full_name,
            }
        )

        return {
            "access_token": token,
            "token_type": "bearer",
        }

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

        user.password_hash = hash_password(new_password)

        return self.repo.update(user)