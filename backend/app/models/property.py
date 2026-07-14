from sqlalchemy import Column, Integer, String

from app.database.base import Base


class Property(Base):
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String, nullable=False)

    property_type = Column(String, nullable=False)

    address = Column(String)

    city = Column(String)

    state = Column(String)

    country = Column(String)

    pincode = Column(String)