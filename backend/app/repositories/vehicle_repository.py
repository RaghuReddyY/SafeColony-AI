from sqlalchemy.orm import Session

from app.models.vehicle import Vehicle


class VehicleRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, vehicle: Vehicle):
        self.db.add(vehicle)
        self.db.commit()
        self.db.refresh(vehicle)
        return vehicle

    def get_all(self):
        return self.db.query(Vehicle).all()

    def get_by_resident(self, resident_id: int):
        return (
            self.db.query(Vehicle)
            .filter(Vehicle.resident_id == resident_id)
            .all()
        )

    def get_by_vehicle_number(self, vehicle_number: str):
        return (
            self.db.query(Vehicle)
            .filter(Vehicle.vehicle_number == vehicle_number)
            .first()
        )