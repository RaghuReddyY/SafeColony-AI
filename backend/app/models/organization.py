from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Integer,
    String,
)
from sqlalchemy.orm import relationship
import sqlalchemy as sa
from sqlalchemy.sql import func

from app.database.base_class import Base


class Organization(Base):
    __tablename__ = "organizations"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    name = Column(
        String(150),
        nullable=False,
    )

    organization_code = Column(
        String(20),
        unique=True,
        nullable=False,
        index=True,
    )

    organization_type = Column(
        String(50),
        nullable=False,
    )

    email = Column(
        String(150),
        unique=True,
    )

    phone = Column(
        String(20),
        unique=True,
    )

    # Maintenance payment configuration.
    # RAZORPAY uses backend environment credentials.
    # DIRECT_UPI stores only the public UPI details shown to residents.
    payment_mode = Column(
        String(20),
        nullable=False,
        default="RAZORPAY",
        server_default="RAZORPAY",
    )

    payment_upi_id = Column(
        String(120),
        nullable=True,
    )

    payment_display_name = Column(
        String(150),
        nullable=True,
    )

    payment_phone = Column(
        String(20),
        nullable=True,
    )

    # Maintenance late-fee policy.
    late_fee_type = Column(
        String(20),
        nullable=False,
        default="NONE",
        server_default="NONE",
    )
    late_fee_value = Column(
        sa.Numeric(12, 2),
        nullable=False,
        default=0,
        server_default="0",
    )
    late_fee_grace_days = Column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
    )

    address = Column(
        String(255),
    )

    city = Column(
        String(100),
    )

    state = Column(
        String(100),
    )

    country = Column(
        String(100),
    )

    pincode = Column(
        String(20),
    )

    is_active = Column(
        Boolean,
        default=True,
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    users = relationship(
        "User",
        back_populates="organization",
    )

    properties = relationship(
        "Property",
        back_populates="organization",
        cascade="all, delete-orphan",
    )