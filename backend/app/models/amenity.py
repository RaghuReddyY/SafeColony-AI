from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class Amenity(Base):
    """Bookable community amenity such as clubhouse, gym, pool or sports facility."""

    __tablename__ = "amenities"
    __table_args__ = (
        Index("ix_amenity_org_active", "organization_id", "is_active"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(
        ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    amenity_type: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    location: Mapped[str | None] = mapped_column(String(200), nullable=True)
    capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)
    booking_required: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    approval_required: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    opening_time: Mapped[str | None] = mapped_column(String(10), nullable=True)
    closing_time: Mapped[str | None] = mapped_column(String(10), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    bookings = relationship("AmenityBooking", back_populates="amenity", cascade="all, delete-orphan")


class AmenityBooking(Base):
    """Resident amenity reservation and approval workflow."""

    __tablename__ = "amenity_bookings"
    __table_args__ = (
        Index("ix_amenity_booking_amenity_time", "amenity_id", "start_at", "end_at"),
        Index("ix_amenity_booking_resident", "resident_id"),
        Index("ix_amenity_booking_status", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    amenity_id: Mapped[int] = mapped_column(
        ForeignKey("amenities.id", ondelete="CASCADE"), nullable=False
    )
    resident_id: Mapped[int] = mapped_column(
        ForeignKey("residents.id", ondelete="CASCADE"), nullable=False
    )
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    start_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    purpose: Mapped[str | None] = mapped_column(String(300), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False, index=True)
    approved_by_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    approved_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    amenity = relationship("Amenity", back_populates="bookings")
    resident = relationship("Resident")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    approved_by = relationship("User", foreign_keys=[approved_by_user_id])
