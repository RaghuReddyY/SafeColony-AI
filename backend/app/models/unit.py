from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Unit(Base):
    __tablename__ = "units"

    id: Mapped[int] = mapped_column(primary_key=True)

    property_id: Mapped[int] = mapped_column(
        ForeignKey("properties.id"),
        nullable=False,
    )

    section_id: Mapped[int] = mapped_column(
        ForeignKey("sections.id"),
        nullable=False,
    )

    unit_number: Mapped[str] = mapped_column(String(30), nullable=False)

    unit_type: Mapped[str] = mapped_column(
        String(30),
        default="Apartment",
    )

    floor: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    owner_name: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    occupancy_status: Mapped[str] = mapped_column(
        String(30),
        default="VACANT",
    )

    intercom_number: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
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

    # Relationships
    property = relationship(
        "Property",
        back_populates="units",
    )

    section = relationship(
        "Section",
        back_populates="units",
    )
    residents = relationship(
        "Resident",
        back_populates="unit",
        cascade="all, delete-orphan",
    )