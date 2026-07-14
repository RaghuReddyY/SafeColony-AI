from fastapi import HTTPException

from app.models.organization import Organization


class OrganizationService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        existing = self.repo.get_by_name(data.name)

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Organization already exists"
            )

        organization = Organization(
            name=data.name,
            organization_type=data.organization_type,
            email=data.email,
            phone=data.phone,
            address=data.address,
            city=data.city,
            state=data.state,
            country=data.country,
            pincode=data.pincode,
        )

        return self.repo.create(organization)

    def get_all(self):

        return self.repo.get_all()