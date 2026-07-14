from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.resident_repository import ResidentRepository
from app.services.resident_service import ResidentService

from app.schemas.resident import (
    ResidentCreate,
    ResidentResponse,
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