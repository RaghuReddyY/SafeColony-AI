from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.vehicle_repository import VehicleRepository
from app.security.permissions import Permissions
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
    dependencies=[
        Depends(
            require_permission(
                Permissions.VEHICLE_CREATE,
            )
        )
    ],
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
    dependencies=[
        Depends(
            require_permission(
                Permissions.VEHICLE_VIEW,
            )
        )
    ],
)
def get_all_vehicles(
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.get_all()


@router.get(
    "/search/{vehicle_number}",
    response_model=VehicleResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VEHICLE_VIEW,
            )
        )
    ],
)
def get_vehicle_by_number(
    vehicle_number: str,
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.get_by_vehicle_number(vehicle_number)


@router.get(
    "/resident/{resident_id}",
    response_model=list[VehicleResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.VEHICLE_VIEW,
            )
        )
    ],
)
def get_vehicles_by_resident(
    resident_id: int,
    db: Session = Depends(get_db),
):
    repo = VehicleRepository(db)
    service = VehicleService(repo)

    return service.get_by_resident(resident_id)