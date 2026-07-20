from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.section_repository import SectionRepository
from app.schemas.section import (
    SectionCreate,
    SectionResponse,
)
from app.services.section_service import SectionService

router = APIRouter(
    prefix="/sections",
    tags=["Sections"],
)


def get_section_service(
    db: Session = Depends(get_db),
) -> SectionService:
    repo = SectionRepository(db)
    return SectionService(repo)


@router.post(
    "",
    response_model=SectionResponse,
    status_code=201,
    summary="Create Section",
)
def create_section(
    section: SectionCreate,
    service: SectionService = Depends(get_section_service),
):
    return service.create(section)


@router.get(
    "",
    response_model=list[SectionResponse],
    summary="Get All Sections",
)
def get_sections(
    service: SectionService = Depends(get_section_service),
):
    return service.get_all()


@router.get(
    "/property/{property_id}",
    response_model=list[SectionResponse],
    summary="Get Sections by Property",
)
def get_sections_by_property(
    property_id: int,
    service: SectionService = Depends(get_section_service),
):
    return service.get_by_property(property_id)