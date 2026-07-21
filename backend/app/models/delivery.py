from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Delivery(Base):

    __tablename__ = "deliveries"

    # -------------------------------------------------
    # Primary Key
    # -------------------------------------------------

    id: Mapped[int] = mapped_column(
        primary_key=True,
    )

    # -------------------------------------------------
    # Resident
    # -------------------------------------------------

    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id"),
        nullable=False,
        index=True,
    )

    # -------------------------------------------------
    # Courier Information
    # -------------------------------------------------

    courier_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    tracking_number: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
        index=True,
    )

    # Package / Food / Grocery / Medicine
    delivery_category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )

    # -------------------------------------------------
    # AI Features
    # -------------------------------------------------

    package_photo: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    # OTP used during collection
    otp: Mapped[str | None] = mapped_column(
        String(10),
        nullable=True,
    )

    # -------------------------------------------------
    # Delivery Priority
    # -------------------------------------------------

    priority: Mapped[str] = mapped_column(
        String(20),
        default="NORMAL",
        index=True,
    )

    # NORMAL
    # URGENT
    # MEDICINE
    # PERISHABLE

    # -------------------------------------------------
    # Status
    # -------------------------------------------------

    status: Mapped[str] = mapped_column(
        String(30),
        default="ARRIVED",
        index=True,
    )

    # ARRIVED
    # NOTIFIED
    # COLLECTED
    # RETURNED

    # -------------------------------------------------
    # Guard Information
    # -------------------------------------------------

    received_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    # -------------------------------------------------
    # Timestamps
    # -------------------------------------------------

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )

    collected_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
        index=True,
    )

    # -------------------------------------------------
    # Relationships
    # -------------------------------------------------

    resident = relationship(
        "Resident",
        back_populates="deliveries",
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )