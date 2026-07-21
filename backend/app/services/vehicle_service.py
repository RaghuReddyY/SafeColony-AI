from datetime import datetime

from app.core.exceptions import (
    ConflictException,
    NotFoundException,
)
from app.core.logger import logger

from app.enums.vehicle_status import VehicleStatus

from app.models.vehicle import Vehicle

from app.repositories.vehicle_repository import VehicleRepository


class VehicleService:

    def __init__(
        self,
        repo: VehicleRepository,
    ):
        self.repo = repo

    # --------------------------------------------------
    # Create
    # --------------------------------------------------

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
            "Vehicle Registered: %s Resident=%s",
            vehicle.vehicle_number,
            vehicle.resident_id,
        )

        return self.repo.create(vehicle)

    # --------------------------------------------------
    # Queries
    # --------------------------------------------------

    def get_all(self):
        return self.repo.get_all()

    def get_by_resident(
        self,
        resident_id: int,
    ):
        return self.repo.get_by_resident(resident_id)

    def get_by_vehicle_number(
        self,
        vehicle_number: str,
    ):

        vehicle = self.repo.get_by_vehicle_number(
            vehicle_number
        )

        if not vehicle:
            raise NotFoundException(
                "Vehicle"
            )

        return vehicle

    def pending_vehicles(self):
        return self.repo.pending_vehicles()

    # --------------------------------------------------
    # Guard Operations
    # --------------------------------------------------

    def vehicle_entry(
        self,
        vehicle_id: int,
        security_guard: str,
    ):

        vehicle = self.repo.get_by_id(
            vehicle_id
        )

        if not vehicle:
            raise NotFoundException(
                "Vehicle"
            )

        vehicle.status = VehicleStatus.INSIDE.value
        vehicle.entry_time = datetime.utcnow()
        vehicle.entered_by = security_guard

        logger.info(
            "Vehicle Entered: %s by %s",
            vehicle.vehicle_number,
            security_guard,
        )

        return self.repo.save(vehicle)

    def vehicle_exit(
        self,
        vehicle_id: int,
        security_guard: str,
    ):

        vehicle = self.repo.get_by_id(
            vehicle_id
        )

        if not vehicle:
            raise NotFoundException(
                "Vehicle"
            )

        vehicle.status = VehicleStatus.OUTSIDE.value
        vehicle.exit_time = datetime.utcnow()
        vehicle.exited_by = security_guard

        logger.info(
            "Vehicle Exited: %s by %s",
            vehicle.vehicle_number,
            security_guard,
        )

        return self.repo.save(vehicle)