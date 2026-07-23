from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.models.user import User

from app.repositories.property_repository import PropertyRepository
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

    return SectionService(
        SectionRepository(db),
        PropertyRepository(db),
    )


@router.post(
    "",
    response_model=SectionResponse,
    status_code=201,
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
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    return service.create(
        current_user,
        section,
    )


@router.get(
    "",
    response_model=list[SectionResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.SECTION_VIEW
            )
        )
    ],
)
def get_sections(
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    return service.get_all(current_user)


@router.get(
    "/{section_id}",
    response_model=SectionResponse,
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
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    return service.get(
        current_user,
        section_id,
    )


@router.get(
    "/property/{property_id}",
    response_model=list[SectionResponse],
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
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    return service.get_by_property(
        current_user,
        property_id,
    )


@router.put(
    "/{section_id}",
    response_model=SectionResponse,
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
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    return service.update(
        current_user,
        section_id,
        section,
    )


@router.delete(
    "/{section_id}",
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
    current_user: User = Depends(get_current_user),
    service: SectionService = Depends(get_section_service),
):
    service.delete(
        current_user,
        section_id,
    )

    return {
        "success": True,
        "message": "Section deleted successfully.",
    }