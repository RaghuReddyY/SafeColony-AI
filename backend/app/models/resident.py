from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
)

from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.database.base_class import Base
from app.enums import ResidentStatus, ResidentType


class Resident(Base):
    __tablename__ = "residents"

    __table_args__ = (
        Index("ix_resident_unit_id", "unit_id"),
        Index("ix_resident_status", "status"),
    )

    id: Mapped[int] = mapped_column(
        primary_key=True,
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        unique=True,
        nullable=False,
        index=True,
    )

    unit_id: Mapped[int | None] = mapped_column(
        ForeignKey("units.id"),
        nullable=True,
        index=True,
    )

    status: Mapped[ResidentStatus] = mapped_column(
        Enum(
            ResidentStatus,
            name="residentstatus",
            create_type=False,
        ),
        default=ResidentStatus.PENDING,
        nullable=False,
    )

    resident_type: Mapped[ResidentType] = mapped_column(
        Enum(
            ResidentType,
            name="residenttype",
            create_type=False,
        ),
        default=ResidentType.OWNER,
        nullable=False,
    )

    gender: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    date_of_birth: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    emergency_contact: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    emergency_contact_name: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    is_primary: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    # ---------------------------------------
    # Relationships
    # ---------------------------------------

    user = relationship(
        "User",
        back_populates="resident",
    )

    unit = relationship(
        "Unit",
        back_populates="residents",
    )

    vehicles = relationship(
        "Vehicle",
        back_populates="resident",
        cascade="all, delete-orphan",
    )

    visitors = relationship(
        "Visitor",
        back_populates="resident",
        cascade="all, delete-orphan",
    )

    deliveries = relationship(
        "Delivery",
        back_populates="resident",
    )

    notifications = relationship(
        "Notification",
        back_populates="resident",
        cascade="all, delete-orphan",
    )

    vacation_modes = relationship(
        "VacationMode",
        back_populates="resident",
        cascade="all, delete-orphan",
    )