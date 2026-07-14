from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Visitor(Base):
    __tablename__ = "visitors"

    id: Mapped[int] = mapped_column(primary_key=True)

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
    )

    visitor_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    phone: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )

    visitor_type: Mapped[str] = mapped_column(
        String(30),
        default="Guest",
    )

    purpose: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    vehicle_number: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    expected_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    status: Mapped[str] = mapped_column(
        String(30),
        default="PENDING",
    )

    # -------------------------
    # NEW QR FIELDS
    # -------------------------

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

    # -------------------------

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )

    check_in_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    check_out_time: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    resident = relationship(
        "Resident",
        back_populates="visitors",
    )