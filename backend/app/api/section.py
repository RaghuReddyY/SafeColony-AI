from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.section_repository import SectionRepository
from app.schemas.section import SectionCreate, SectionResponse
from app.services.section_service import SectionService


router = APIRouter(
    prefix="/sections",
    tags=["Sections"],
)


@router.post("", response_model=SectionResponse)
def create_section(
    section: SectionCreate,
    db: Session = Depends(get_db),
):
    repo = SectionRepository(db)
    service = SectionService(repo)

    return service.create(section)


@router.get("", response_model=list[SectionResponse])
def get_sections(
    db: Session = Depends(get_db),
):
    repo = SectionRepository(db)
    service = SectionService(repo)

    return service.get_all()


@router.get("/property/{property_id}", response_model=list[SectionResponse])
def get_sections_by_property(
    property_id: int,
    db: Session = Depends(get_db),
):
    repo = SectionRepository(db)
    service = SectionService(repo)

    return service.get_by_property(property_id)