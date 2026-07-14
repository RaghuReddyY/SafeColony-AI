from fastapi import HTTPException

from app.models.resident import Resident


class ResidentService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        existing = self.repo.get_by_phone(data.phone)

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Phone number already exists"
            )

        resident = Resident(
            unit_id=data.unit_id,
            full_name=data.full_name,
            email=data.email,
            phone=data.phone,
            resident_type=data.resident_type,
            gender=data.gender,
            date_of_birth=data.date_of_birth,
            emergency_contact=data.emergency_contact,
            emergency_contact_name=data.emergency_contact_name,
            is_primary=data.is_primary,
        )

        return self.repo.create(resident)

    def get_all(self):
        return self.repo.get_all()

    def get_by_unit(self, unit_id):
        return self.repo.get_by_unit(unit_id)