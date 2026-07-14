from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.unit_repository import UnitRepository
from app.services.unit_service import UnitService

from app.schemas.unit import UnitCreate, UnitResponse


router = APIRouter(
    prefix="/units",
    tags=["Units"],
)


@router.post(
    "",
    response_model=UnitResponse,
)
def create_unit(
    unit: UnitCreate,
    db: Session = Depends(get_db),
):
    repo = UnitRepository(db)
    service = UnitService(repo)

    return service.create(unit)


@router.get(
    "",
    response_model=list[UnitResponse],
)
def get_units(
    db: Session = Depends(get_db),
):
    repo = UnitRepository(db)
    service = UnitService(repo)

    return service.get_all()


@router.get(
    "/section/{section_id}",
    response_model=list[UnitResponse],
)
def get_units_by_section(
    section_id: int,
    db: Session = Depends(get_db),
):
    repo = UnitRepository(db)
    service = UnitService(repo)

    return service.get_by_section(section_id)