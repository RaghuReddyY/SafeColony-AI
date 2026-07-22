from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    Enum,
    UniqueConstraint,
)

from sqlalchemy.orm import relationship

from app.database.base_class import Base
from app.enums import PropertyType


class Property(Base):

    __tablename__ = "properties"

    __table_args__ = (
        UniqueConstraint(
            "organization_id",
            "name",
            name="uq_property_organization_name",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    name = Column(
        String(100),
        nullable=False,
    )

    property_type = Column(
        Enum(PropertyType),
        nullable=False,
    )

    organization_id = Column(
        Integer,
        ForeignKey(
            "organizations.id",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    organization = relationship(
        "Organization",
        back_populates="properties",
    )

    sections = relationship(
        "Section",
        back_populates="property",
        cascade="all, delete",
    )

    units = relationship(
        "Unit",
        back_populates="property",
        cascade="all, delete",
    )

    address = Column(
        String,
        nullable=True,
    )

    city = Column(
        String,
        nullable=True,
    )

    state = Column(
        String,
        nullable=True,
    )

    country = Column(
        String,
        nullable=True,
    )

    pincode = Column(
        String,
        nullable=True,
    )