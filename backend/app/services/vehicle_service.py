from app.models.vehicle import Vehicle
from app.core.exceptions import (
    ConflictException,
)
from app.repositories.vehicle_repository import VehicleRepository
from app.core.logger import logger
from app.core.exceptions import (
    ConflictException,
    NotFoundException,
)

from app.models.vehicle import Vehicle
from app.repositories.vehicle_repository import VehicleRepository

class VehicleService:

    def __init__(self, repo: VehicleRepository):
        self.repo = repo

    def create(self, data):

        existing = self.repo.get_by_vehicle_number(
            data.vehicle_number
        )

        if existing:
            raise ConflictException(
                "Vehicle already registered."
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

        logger.info(
            "Vehicle Registered: %s (Resident=%s)",
            vehicle.vehicle_number,
            vehicle.resident_id,
        )
        return self.repo.create(vehicle)

    def get_all(self):
        return self.repo.get_all()

    def get_by_resident(self, resident_id):
        return self.repo.get_by_resident(resident_id)
    
    def get_by_vehicle_number(
            self,
            vehicle_number: str,
        ):
            vehicle = self.repo.get_by_vehicle_number(vehicle_number)

            if not vehicle:
                raise NotFoundException("Vehicle")

            return vehicle