from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
)
from sqlalchemy.sql import func

from app.database.base_class import Base
from app.enums import OrganizationApplicationStatus
from sqlalchemy.orm import relationship


class OrganizationApplication(Base):
    __tablename__ = "organization_applications"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    organization_name = Column(
        String(150),
        nullable=False,
    )

    organization_type = Column(
        String(50),
        nullable=False,
    )

    contact_person = Column(
        String(100),
        nullable=False,
    )

    email = Column(
        String(150),
        nullable=False,
        index=True,
    )

    phone = Column(
        String(20),
        nullable=False,
        index=True,
    )

    password_hash = Column(
        String(255),
        nullable=False,
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

    status = Column(
        String(20),
        default=OrganizationApplicationStatus.PENDING.value,
        nullable=False,
        index=True,
    )

    rejection_reason = Column(
        String(500),
        nullable=True,
    )

    approved_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    approved_by_user = relationship(
        "User",
        foreign_keys=[approved_by],
    )

    approved_at = Column(
        DateTime(timezone=True),
        nullable=True,
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