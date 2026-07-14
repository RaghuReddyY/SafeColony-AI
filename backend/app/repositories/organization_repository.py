from sqlalchemy.orm import Session

from app.models.organization import Organization


class OrganizationRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, organization):

        self.db.add(organization)

        self.db.commit()

        self.db.refresh(organization)

        return organization

    def get_all(self):

        return self.db.query(Organization).all()

    def get_by_name(self, name):

        return (
            self.db.query(Organization)
            .filter(Organization.name == name)
            .first()
        )