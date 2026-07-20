from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.unit_repository import UnitRepository
from app.schemas.unit import UnitCreate, UnitResponse
from app.services.unit_service import UnitService


router = APIRouter(
    prefix="/units",
    tags=["Units"],
)


def get_unit_service(
    db: Session = Depends(get_db),
) -> UnitService:
    repo = UnitRepository(db)
    return UnitService(repo)


@router.post(
    "",
    response_model=UnitResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Unit",
)
def create_unit(
    unit: UnitCreate,
    service: UnitService = Depends(get_unit_service),
):
    return service.create(unit)


@router.get(
    "",
    response_model=list[UnitResponse],
    summary="Get All Units",
)
def get_units(
    service: UnitService = Depends(get_unit_service),
):
    return service.get_all()


@router.get(
    "/section/{section_id}",
    response_model=list[UnitResponse],
    summary="Get Units by Section",
)
def get_units_by_section(
    section_id: int,
    service: UnitService = Depends(get_unit_service),
):
    return service.get_by_section(section_id)