from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from app.database.base_class import Base


class Section(Base):
    __tablename__ = "sections"

    id = Column(Integer, primary_key=True, index=True)

    property_id = Column(
        Integer,
        ForeignKey("properties.id"),
        nullable=False,
    )

    name = Column(String(100), nullable=False)

    description = Column(String(255), nullable=True)

    property = relationship("Property", back_populates="sections")

    units = relationship(
    "Unit",
    back_populates="section",
    cascade="all, delete",
)
