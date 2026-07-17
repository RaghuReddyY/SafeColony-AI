from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.resident_repository import ResidentRepository
from app.services.resident_service import ResidentService
from app.schemas.dashboard import ResidentDashboardResponse

from app.schemas.resident import (
    ResidentCreate,
    ResidentResponse,
)

from app.schemas.resident import (
    ResidentProfileResponse,
    ResidentProfileUpdate,
)

router = APIRouter(
    prefix="/residents",
    tags=["Residents"],
)


@router.post(
    "",
    response_model=ResidentResponse,
)
def create_resident(
    resident: ResidentCreate,
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.create(resident)


@router.get(
    "",
    response_model=list[ResidentResponse],
)
def get_residents(
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.get_all()


@router.get(
    "/unit/{unit_id}",
    response_model=list[ResidentResponse],
)
def get_residents_by_unit(
    unit_id: int,
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.get_by_unit(unit_id)

@router.get(
    "/dashboard/{resident_id}",
    response_model=ResidentDashboardResponse,
)
def dashboard(
    resident_id: int,
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.dashboard(resident_id)

@router.get(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
)
def get_profile(
    resident_id: int,
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.get_profile(resident_id)

@router.put(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
)
def update_profile(
    resident_id: int,
    resident: ResidentProfileUpdate,
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)
    service = ResidentService(repo)

    return service.update_profile(
        resident_id,
        resident,
    )

@router.get(
    "/dropdown",
)
def resident_dropdown(
    db: Session = Depends(get_db),
):

    repo = ResidentRepository(db)

    service = ResidentService(repo)

    return service.dropdown()