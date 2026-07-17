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
    
    def dashboard(self, resident_id: int):

        data = self.repo.get_dashboard(resident_id)

        if data is None:
            raise HTTPException(
                status_code=404,
                detail="Resident not found",
            )

        resident = data["resident"]

        return {
            "resident_name": resident.full_name,
            "unit_number": resident.unit.unit_number,
            "vehicles": data["vehicles"],
            "pending_visitors": data["pending"],
            "approved_visitors": data["approved"],
            "inside_visitors": data["inside"],
            "notifications": data["notifications"],
        }
    
    def get_profile(self, resident_id: int):

        resident = self.repo.get_profile(resident_id)

        if resident is None:
            raise HTTPException(
                status_code=404,
                detail="Resident not found",
            )

        return resident
    
    def update_profile(self, resident_id: int, data):

        resident = self.repo.get_profile(resident_id)

        if resident is None:
            raise HTTPException(
                status_code=404,
                detail="Resident not found",
            )

        resident.full_name = data.full_name
        resident.email = data.email
        resident.gender = data.gender
        resident.date_of_birth = data.date_of_birth
        resident.emergency_contact = data.emergency_contact
        resident.emergency_contact_name = data.emergency_contact_name

        return self.repo.update(resident)
    
    def dropdown(self):

        residents = self.repo.get_dropdown()

        return [

            {
                "id": resident.id,

                "name": resident.full_name,

                "flat": resident.unit.unit_number
                if resident.unit
                else "",
            }

            for resident in residents
        ]