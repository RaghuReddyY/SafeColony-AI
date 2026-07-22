from sqlalchemy.orm import Session

from app.auth.hashing import hash_password
from app.core.exceptions import ConflictException

from app.enums import UserRole, UserStatus

from app.models.user import User

from app.repositories.user_repository import UserRepository


class SetupService:

    def __init__(self, db: Session):
        self.db = db
        self.user_repo = UserRepository(db)

    def status(self):

        admin = (
            self.db.query(User)
            .filter(User.role == UserRole.SYSTEM_ADMIN.value)
            .first()
        )

        return {
            "initialized": admin is not None
        }

    def initialize(self, request):

        existing_admin = (
            self.db.query(User)
            .filter(User.role == UserRole.SYSTEM_ADMIN.value)
            .first()
        )

        if existing_admin:
            raise ConflictException(
                "Platform already initialized"
            )

        if self.user_repo.exists_by_email(request.email):
            raise ConflictException(
                "Email already exists"
            )

        if self.user_repo.exists_by_phone(request.phone):
            raise ConflictException(
                "Phone already exists"
            )

        try:

            admin = User(
                full_name=request.full_name,
                email=request.email,
                phone=request.phone,
                password_hash=hash_password(request.password),
                role=UserRole.SYSTEM_ADMIN.value,
                status=UserStatus.ACTIVE.value,
                is_active=True,
            )

            self.user_repo.create(
                admin,
                create_resident=False,
                commit=False,
            )

            self.db.commit()

            self.db.refresh(admin)

            return {
                "message": "Platform initialized successfully",
                "user_id": admin.id,
                "email": admin.email,
                "role": admin.role,
            }

        except Exception:
            self.db.rollback()
            raise