from fastapi import HTTPException

from app.models.vehicle import Vehicle


class VehicleService:

    def __init__(self, repo):
        self.repo = repo

    def create(self, data):

        existing = self.repo.get_by_vehicle_number(
            data.vehicle_number
        )

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Vehicle already registered"
            )

        vehicle = Vehicle(
            resident_id=data.resident_id,
            vehicle_number=data.vehicle_number,
            vehicle_type=data.vehicle_type,
            brand=data.brand,
            model=data.model,
            color=data.color,
            parking_slot=data.parking_slot,
        )

        return self.repo.create(vehicle)

    def get_all(self):
        return self.repo.get_all()

    def get_by_resident(self, resident_id):
        return self.repo.get_by_resident(resident_id)
    
    def get_by_resident(self, resident_id: int):
        return self.repo.get_by_resident(resident_id)