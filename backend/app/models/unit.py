from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    String,
    UniqueConstraint,
    Enum,
)

from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.database.base_class import Base
from app.enums import UnitType, OccupancyStatus


class Unit(Base):

    __tablename__ = "units"

    __table_args__ = (
        UniqueConstraint(
            "section_id",
            "unit_number",
            name="uq_section_unit_number",
        ),
    )

    id: Mapped[int] = mapped_column(
        primary_key=True,
    )

    property_id: Mapped[int] = mapped_column(
        ForeignKey(
            "properties.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    section_id: Mapped[int] = mapped_column(
        ForeignKey(
            "sections.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    unit_number: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
    )

    unit_type: Mapped[UnitType] = mapped_column(
        Enum(UnitType),
        default=UnitType.APARTMENT,
        nullable=False,
    )

    floor: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    owner_name: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    occupancy_status: Mapped[OccupancyStatus] = mapped_column(
        Enum(OccupancyStatus),
        default=OccupancyStatus.VACANT,
        nullable=False,
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