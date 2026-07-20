from sqlalchemy import Column, Integer, String

from app.database.base_class import Base
from sqlalchemy.orm import relationship

class Property(Base):
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String, nullable=False)

    property_type = Column(String, nullable=False)

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
    
    address = Column(String)

    city = Column(String)

    state = Column(String)

    country = Column(String)

    pincode = Column(String)