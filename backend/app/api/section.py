from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.section_repository import SectionRepository
from app.schemas.section import (
    SectionCreate,
    SectionResponse,
)

from app.security.permissions import Permissions
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
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_CREATE
            )
        )
    ],
)
def create_section(
    section: SectionCreate,
    service: SectionService = Depends(
        get_section_service
    ),
):
    return service.create(section)



@router.get(
    "",
    response_model=list[SectionResponse],
    summary="Get All Sections",
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_VIEW
            )
        )
    ],
)
def get_sections(
    service: SectionService = Depends(
        get_section_service
    ),
):

    return service.get_all()



@router.get(
    "/{section_id}",
    response_model=SectionResponse,
    summary="Get Section By Id",
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_VIEW
            )
        )
    ],
)
def get_section(
    section_id: int,
    service: SectionService = Depends(
        get_section_service
    ),
):

    return service.get(section_id)



@router.get(
    "/property/{property_id}",
    response_model=list[SectionResponse],
    summary="Get Sections By Property",
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_VIEW
            )
        )
    ],
)
def get_sections_by_property(
    property_id: int,
    service: SectionService = Depends(
        get_section_service
    ),
):

    return service.get_by_property(
        property_id
    )



@router.put(
    "/{section_id}",
    response_model=SectionResponse,
    summary="Update Section",
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_UPDATE
            )
        )
    ],
)
def update_section(
    section_id: int,
    section: SectionCreate,
    service: SectionService = Depends(
        get_section_service
    ),
):

    return service.update(
        section_id,
        section,
    )



@router.delete(
    "/{section_id}",
    summary="Delete Section",
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_DELETE
            )
        )
    ],
)
def delete_section(
    section_id: int,
    service: SectionService = Depends(
        get_section_service
    ),
):

    service.delete(section_id)

    return {
        "success": True,
        "message": "Section deleted successfully.",
    }