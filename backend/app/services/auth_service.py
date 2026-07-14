from fastapi import HTTPException

from app.auth.hashing import hash_password, verify_password
from app.auth.jwt_handler import create_access_token
from app.models.user import User
from app.repositories.user_repository import UserRepository


class AuthService:

    def __init__(self, repo: UserRepository):
        self.repo = repo

    def login(self, email: str, password: str):

        # Find user by email
        user = self.repo.get_by_email(email)

        if not user:
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
            )

        # Verify password
        if not verify_password(password, user.password):
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
            )

        # Create JWT token
        token = create_access_token(
            {
                "sub": user.email,
                "user_id": user.id,
                "role": user.role,
            }
        )

        return {
            "access_token": token,
            "token_type": "bearer",
        }

    def register(self, data):

        existing = self.repo.get_by_email(data.email)

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Email already exists",
            )

        existing_phone = self.repo.get_by_phone(data.phone)

        if existing_phone:
            raise HTTPException(
                status_code=400,
                detail="Phone number already exists",
            )

        user = User(
            full_name=data.full_name,
            email=data.email,
            phone=data.phone,
            password=hash_password(data.password),
            role="resident",
        )

        return self.repo.create(user)