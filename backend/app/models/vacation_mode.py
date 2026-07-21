from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
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
from app.enums.delivery_policy import DeliveryPolicy
from app.enums.vacation_status import VacationStatus
from app.enums.visitor_policy import VisitorPolicy


class VacationMode(Base):
    """
    Represents a resident's vacation period.
    """

    __tablename__ = "vacation_modes"

    __table_args__ = (
        Index("idx_vacation_resident", "resident_id"),
        Index("idx_vacation_status", "status"),
        Index("idx_vacation_dates", "start_date", "end_date"),
    )

    # -------------------------------------------------
    # Primary Key
    # -------------------------------------------------

    id: Mapped[int] = mapped_column(primary_key=True)

    # -------------------------------------------------
    # Resident
    # -------------------------------------------------

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
    )

    resident = relationship(
        "Resident",
        back_populates="vacation_modes",
        lazy="joined",
    )

    # -------------------------------------------------
    # Vacation Duration
    # -------------------------------------------------

    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    end_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    # -------------------------------------------------
    # Additional Information
    # -------------------------------------------------

    reason: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
    )

    emergency_contact: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    # -------------------------------------------------
    # Policies
    # -------------------------------------------------

    visitor_policy: Mapped[str] = mapped_column(
        String(30),
        default=VisitorPolicy.REJECT_ALL.value,
        nullable=False,
    )

    delivery_policy: Mapped[str] = mapped_column(
        String(30),
        default=DeliveryPolicy.ALLOW.value,
        nullable=False,
    )

    notify_security: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    monitoring_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    # -------------------------------------------------
    # Status
    # -------------------------------------------------

    status: Mapped[str] = mapped_column(
        String(20),
        default=VacationStatus.SCHEDULED.value,
        nullable=False,
    )

    # -------------------------------------------------
    # Audit Fields
    # -------------------------------------------------

    activated_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    deactivated_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
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