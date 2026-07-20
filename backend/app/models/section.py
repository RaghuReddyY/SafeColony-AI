from sqlalchemy import (
    Column,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)

from sqlalchemy.orm import relationship

from app.database.base_class import Base


class Section(Base):
    __tablename__ = "sections"

    __table_args__ = (
        UniqueConstraint(
            "property_id",
            "name",
            name="uq_property_section_name",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    property_id = Column(
        Integer,
        ForeignKey("properties.id"),
        nullable=False,
        index=True,
    )

    name = Column(
        String(100),
        nullable=False,
    )

    description = Column(
        String(255),
        nullable=True,
    )

    property = relationship(
        "Property",
        back_populates="sections",
    )

    units = relationship(
        "Unit",
        back_populates="section",
        cascade="all, delete-orphan",
    )