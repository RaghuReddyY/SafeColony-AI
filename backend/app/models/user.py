from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base
from app.enums import UserRole, UserStatus

if TYPE_CHECKING:
    from app.models.organization import Organization
    from app.models.resident import Resident


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)

    full_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    email: Mapped[str] = mapped_column(
        String(120),
        unique=True,
        index=True,
        nullable=False,
    )

    phone: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        index=True,
        nullable=False,
    )

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    # Store role as STRING in database
    role: Mapped[str] = mapped_column(
        String(30),
        default=UserRole.RESIDENT.value,
        nullable=False,
    )

    # Account approval status
    status: Mapped[str] = mapped_column(
        String(20),
        default=UserStatus.PENDING.value,
        nullable=False,
        index=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    organization_id: Mapped[int | None] = mapped_column(
        ForeignKey("organizations.id"),
        nullable=True,
    )

    organization: Mapped["Organization"] = relationship(
        back_populates="users",
    )

    resident: Mapped["Resident"] = relationship(
        back_populates="user",
        uselist=False,
    )