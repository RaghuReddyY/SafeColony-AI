from sqlalchemy.orm import Session, joinedload

from app.models.user import User
from app.models.resident import Resident
from app.enums.resident_status import ResidentStatus
from app.enums.resident_type import ResidentType


class UserRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        user: User,
        commit: bool = True,
    ) -> User:

        self.db.add(user)
        self.db.flush()

        if commit:
            self.db.commit()
            self.db.refresh(user)

        return user

    def update(self, user: User) -> User:
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_id(self, user_id: int) -> User | None:
        return (
            self.db.query(User)
            .options(joinedload(User.resident))
            .filter(User.id == user_id)
            .first()
        )

    def get_by_email(self, email: str) -> User | None:
        return (
            self.db.query(User)
            .options(joinedload(User.resident))
            .filter(User.email == email)
            .first()
        )

    def get_by_phone(self, phone: str) -> User | None:
        return (
            self.db.query(User)
            .options(joinedload(User.resident))
            .filter(User.phone == phone)
            .first()
        )

    def exists_by_email(self, email: str) -> bool:
        return self.get_by_email(email) is not None

    def exists_by_phone(self, phone: str) -> bool:
        return self.get_by_phone(phone) is not None

        # ==========================================================
    # Guard Management
    # ==========================================================

    def get_guards_by_organization(
        self,
        organization_id: int,
    ):

        return (
            self.db.query(User)
            .filter(
                User.organization_id == organization_id,
                User.role == "SECURITY_GUARD",
            )
            .order_by(User.full_name.asc())
            .all()
        )

    def create_guard(
        self,
        guard: User,
        commit: bool = True,
    ):

        self.db.add(guard)
        self.db.flush()

        if commit:
            self.db.commit()
            self.db.refresh(guard)

        return guard