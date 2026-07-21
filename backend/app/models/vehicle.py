from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base
from app.enums.vehicle_type import VehicleType

class Vehicle(Base):
    __tablename__ = "vehicles"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
        index=True,
    )

    vehicle_number: Mapped[str] = mapped_column(
        String(20),
        unique=True,
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

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        index=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    resident = relationship(
        "Resident",
        back_populates="vehicles",
    )