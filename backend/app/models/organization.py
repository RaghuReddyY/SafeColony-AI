from sqlalchemy import Column, Integer, String

from app.database.base_class import Base
from sqlalchemy.orm import relationship

class Organization(Base):
    __tablename__ = "organizations"

    properties = relationship(
    "Property",
    back_populates="organization",
    cascade="all, delete-orphan",)

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String(150), nullable=False)

    organization_type = Column(String(50), nullable=False)

    email = Column(String(150), unique=True)

    phone = Column(String(20), unique=True)

    address = Column(String(255))

    city = Column(String(100))

    state = Column(String(100))

    country = Column(String(100))

    pincode = Column(String(20))