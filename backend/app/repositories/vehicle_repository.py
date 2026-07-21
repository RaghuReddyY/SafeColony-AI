from sqlalchemy.orm import Session

from app.enums.vehicle_status import VehicleStatus
from app.models.vehicle import Vehicle


class VehicleRepository:

    def __init__(self, db: Session):
        self.db = db

    # --------------------------------------------------
    # Create
    # --------------------------------------------------

    def create(self, vehicle: Vehicle):
        self.db.add(vehicle)
        self.db.commit()
        self.db.refresh(vehicle)
        return vehicle

    # --------------------------------------------------
    # Save Updates
    # --------------------------------------------------

    def save(self, vehicle: Vehicle):
        self.db.commit()
        self.db.refresh(vehicle)
        return vehicle

    # --------------------------------------------------
    # Queries
    # --------------------------------------------------

    def get_all(self):
        return (
            self.db.query(Vehicle)
            .all()
        )

    def get_by_id(
        self,
        vehicle_id: int,
    ):
        return (
            self.db.query(Vehicle)
            .filter(Vehicle.id == vehicle_id)
            .first()
        )

    def get_by_resident(
        self,
        resident_id: int,
    ):
        return (
            self.db.query(Vehicle)
            .filter(Vehicle.resident_id == resident_id)
            .all()
        )

    def get_by_vehicle_number(
        self,
        vehicle_number: str,
    ):
        return (
            self.db.query(Vehicle)
            .filter(
                Vehicle.vehicle_number == vehicle_number
            )
            .first()
        )

    # --------------------------------------------------
    # Guard Operations
    # --------------------------------------------------

    def pending_vehicles(self):
        return (
            self.db.query(Vehicle)
            .filter(
                Vehicle.status == VehicleStatus.OUTSIDE.value,
                Vehicle.is_active.is_(True),
            )
            .all()
        )