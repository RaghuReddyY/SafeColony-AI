from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    String,
)
from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.database.base_class import Base
from app.enums.vehicle_status import VehicleStatus
from app.enums.vehicle_type import VehicleType


class Vehicle(Base):
    __tablename__ = "vehicles"

    # --------------------------------------------------
    # Primary Key
    # --------------------------------------------------

    id: Mapped[int] = mapped_column(
        primary_key=True,
    )

    # --------------------------------------------------
    # Ownership
    # --------------------------------------------------

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
        index=True,
    )

    # --------------------------------------------------
    # Vehicle Details
    # --------------------------------------------------

    vehicle_number: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
        index=True,
    )

    vehicle_type: Mapped[str] = mapped_column(
        String(20),
        default=VehicleType.CAR.value,
    )

    brand: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    model: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    color: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True,
    )

    parking_slot: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    # --------------------------------------------------
    # Guard Operations
    # --------------------------------------------------

    status: Mapped[str] = mapped_column(
        String(20),
        default=VehicleStatus.OUTSIDE.value,
        nullable=False,
        index=True,
    )

    entry_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    exit_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    entered_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    exited_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    # --------------------------------------------------
    # Status
    # --------------------------------------------------

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
    )

    # --------------------------------------------------
    # Audit
    # --------------------------------------------------

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        index=True,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    # --------------------------------------------------
    # Relationships
    # --------------------------------------------------

    resident = relationship(
        "Resident",
        back_populates="vehicles",
    )