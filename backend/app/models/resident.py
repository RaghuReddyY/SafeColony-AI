from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Resident(Base):
    __tablename__ = "residents"

    id: Mapped[int] = mapped_column(primary_key=True)

    unit_id: Mapped[int] = mapped_column(
        ForeignKey("units.id"),
        nullable=False,
    )

    full_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    email: Mapped[str | None] = mapped_column(
        String(120),
        nullable=True,
    )

    phone: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
    )

    resident_type: Mapped[str] = mapped_column(
        String(20),
        default="OWNER",
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
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    # -------------------------
    # Relationships
    # -------------------------

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

