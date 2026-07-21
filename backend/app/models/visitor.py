from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base
from app.enums.visitor_status import VisitorStatus
from app.enums.visitor_type import VisitorType
from app.enums.entry_mode import EntryMode
from app.enums.approval_mode import ApprovalMode

class Visitor(Base):
    __tablename__ = "visitors"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
        index=True,
    )

    visitor_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    phone: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
    )

    visitor_type: Mapped[str] = mapped_column(
        String(30),
        default=VisitorType.GUEST.value,
    )

    purpose: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    vehicle_number: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
        index=True,
    )

    expected_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    status: Mapped[str] = mapped_column(
        String(30),
        default=VisitorStatus.PENDING.value,
        index=True,
    )



    # ----------------------------------------------------
    # Walk-in Visitor Information
    # ----------------------------------------------------

    entry_mode: Mapped[str] = mapped_column(
        String(20),
        default=EntryMode.QR.value,
    )

    approval_mode: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    visitor_photo: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    created_by_guard: Mapped[bool] = mapped_column(
        default=False,
    )

# ----------------------------------------------------
# QR Information
# ----------------------------------------------------
    # ----------------------------------------------------
    # QR Information
    # ----------------------------------------------------

    qr_token: Mapped[str | None] = mapped_column(
        String(100),
        unique=True,
        nullable=True,
    )

    qr_code: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    approved_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    # ----------------------------------------------------
    # Guard Entry Information
    # ----------------------------------------------------

    check_in_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
        index=True,
    )

    check_out_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

      # ----------------------------------------------------

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
        back_populates="visitors",
    )

