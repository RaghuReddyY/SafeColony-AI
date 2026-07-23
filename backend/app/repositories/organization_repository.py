from sqlalchemy.orm import Session

from app.models.organization import Organization


class OrganizationRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, organization: Organization, commit: bool = True):

        self.db.add(organization)

        if commit:
            self.db.commit()
            self.db.refresh(organization)
        else:
            self.db.flush()

        return organization

    def get_all(self):

        return self.db.query(Organization).all()

    def get_by_name(self, name: str):

        return (
            self.db.query(Organization)
            .filter(Organization.name == name)
            .first()
        )

    def get_by_email(self, email: str):

        return (
            self.db.query(Organization)
            .filter(Organization.email == email)
            .first()
        )

    def get_by_code(self, code: str):

        return (
            self.db.query(Organization)
            .filter(Organization.organization_code == code)
            .first()
        )
    
    def get_by_id(self, organization_id: int):

        return (
            self.db.query(Organization)
            .filter(Organization.id == organization_id)
            .first()
        )
    
    def get_by_phone(self, phone: str):
        return (
            self.db.query(Organization)
            .filter(Organization.phone == phone)
            .first()
        )