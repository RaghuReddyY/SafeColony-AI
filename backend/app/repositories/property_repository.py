from sqlalchemy.orm import Session

from app.models.property import Property


class PropertyRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, property):

        self.db.add(property)

        self.db.commit()

        self.db.refresh(property)

        return property

    def get_all(self):

        return self.db.query(Property).all()

    def get(self, property_id):

        return self.db.query(Property).filter(
            Property.id == property_id
        ).first()