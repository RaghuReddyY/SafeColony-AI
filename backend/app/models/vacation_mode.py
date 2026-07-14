from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class VacationMode(Base):

    __tablename__ = "vacation_modes"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
    )

    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    end_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    reason: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
    )

    emergency_contact: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    allow_visitors: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )

    allow_deliveries: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    notify_security: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    monitoring_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    status: Mapped[str] = mapped_column(
        String(20),
        default="ACTIVE",
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )

    resident = relationship(
        "Resident",
        back_populates="vacation_modes",
    )