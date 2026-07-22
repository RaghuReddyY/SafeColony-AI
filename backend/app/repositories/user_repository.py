from sqlalchemy.orm import Session

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
        create_resident: bool = True,
        commit: bool = True,
    ) -> User:
        """
        Create a User.

        Parameters:
        - create_resident:
            True  -> Automatically create a Resident profile.
            False -> Only create the User.

        - commit:
            True  -> Commit immediately.
            False -> Leave transaction open for the service layer.
        """

        self.db.add(user)
        self.db.flush()

        if create_resident:
            resident = Resident(
                user_id=user.id,
                status=ResidentStatus.PENDING,
                resident_type=ResidentType.OWNER,
                is_active=True,
            )

            self.db.add(resident)

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
            .filter(User.id == user_id)
            .first()
        )

    def get_by_email(self, email: str) -> User | None:
        return (
            self.db.query(User)
            .filter(User.email == email)
            .first()
        )

    def get_by_phone(self, phone: str) -> User | None:
        return (
            self.db.query(User)
            .filter(User.phone == phone)
            .first()
        )

    def exists_by_email(self, email: str) -> bool:
        return self.get_by_email(email) is not None

    def exists_by_phone(self, phone: str) -> bool:
        return self.get_by_phone(phone) is not None