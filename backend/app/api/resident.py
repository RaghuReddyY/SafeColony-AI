from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.resident_repository import ResidentRepository
from app.schemas.dashboard import ResidentDashboardResponse
from app.schemas.resident import (
    ResidentCreate,
    ResidentProfileResponse,
    ResidentProfileUpdate,
    ResidentResponse,
)
from app.services.resident_service import ResidentService

router = APIRouter(
    prefix="/residents",
    tags=["Residents"],
)


def get_resident_service(
    db: Session = Depends(get_db),
) -> ResidentService:
    repo = ResidentRepository(db)
    return ResidentService(repo)


@router.post(
    "",
    response_model=ResidentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Resident",
)
def create_resident(
    resident: ResidentCreate,
    service: ResidentService = Depends(get_resident_service),
):
    return service.create(resident)


@router.get(
    "",
    response_model=list[ResidentResponse],
    summary="Get All Residents",
)
def get_residents(
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_all()


@router.get(
    "/unit/{unit_id}",
    response_model=list[ResidentResponse],
    summary="Get Residents by Unit",
)
def get_residents_by_unit(
    unit_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_by_unit(unit_id)


@router.get(
    "/dashboard/{resident_id}",
    response_model=ResidentDashboardResponse,
    summary="Resident Dashboard",
)
def dashboard(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.dashboard(resident_id)


@router.get(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
    summary="Resident Profile",
)
def get_profile(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_profile(resident_id)


@router.put(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
    summary="Update Resident Profile",
)
def update_profile(
    resident_id: int,
    resident: ResidentProfileUpdate,
    service: ResidentService = Depends(get_resident_service),
):
    return service.update_profile(
        resident_id,
        resident,
    )


@router.get(
    "/dropdown",
    summary="Resident Dropdown",
)
def resident_dropdown(
    service: ResidentService = Depends(get_resident_service),
):
    return service.dropdown()