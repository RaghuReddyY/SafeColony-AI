from fastapi import HTTPException, status

from app.models.resident import Resident
from app.models.unit import Unit


class ResidentService:

    def __init__(self, repo):
        self.repo = repo
        self.db = repo.db

    def create(self, data):

        # -----------------------------
        # Validate Unit
        # -----------------------------
        unit = (
            self.db.query(Unit)
            .filter(Unit.id == data.unit_id)
            .first()
        )

        if unit is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Unit with id {data.unit_id} not found.",
            )

        # -----------------------------
        # Validate Phone
        # -----------------------------
        if self.repo.get_by_phone(data.phone):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone number already exists.",
            )

        # -----------------------------
        # Validate Email
        # -----------------------------
        if data.email:

            existing = self.repo.get_by_email(data.email)

            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already exists.",
                )

        # -----------------------------
        # Validate Primary Resident
        # -----------------------------
        if data.is_primary:

            primary = self.repo.get_primary_by_unit(
                data.unit_id,
            )

            if primary:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Primary resident already exists for this unit.",
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

        resident = self.repo.create(resident)

        # -----------------------------
        # Update Unit Occupancy
        # -----------------------------
        if unit.occupancy_status == "VACANT":
            unit.occupancy_status = "OCCUPIED"
            self.db.commit()

        return resident

    def get_all(self):
        return self.repo.get_all()

    def get_by_unit(self, unit_id: int):
        return self.repo.get_by_unit(unit_id)

    def dashboard(self, resident_id: int):

        data = self.repo.get_dashboard(resident_id)

        if data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
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
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resident not found",
            )

        return resident

    def update_profile(self, resident_id: int, data):

        resident = self.repo.get_profile(resident_id)

        if resident is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resident not found",
            )

        if (
            data.email
            and data.email != resident.email
        ):
            existing = self.repo.get_by_email(data.email)

            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already exists.",
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