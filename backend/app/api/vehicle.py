from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.vehicle_repository import VehicleRepository
from app.services.vehicle_service import VehicleService

from app.schemas.vehicle import (
    VehicleCreate,
    VehicleResponse,
)

router = APIRouter(
    prefix="/vehicles",
    tags=["Vehicles"],
)


@router.post(
    "",
    response_model=VehicleResponse,
)
def create_vehicle(
    vehicle: VehicleCreate,
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.create(vehicle)


@router.get(
    "",
    response_model=list[VehicleResponse],
)
def get_all_vehicles(
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.get_all()


@router.get(
    "/resident/{resident_id}",
    response_model=list[VehicleResponse],
)
def get_vehicle_by_resident(
    resident_id: int,
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.get_by_resident(resident_id)