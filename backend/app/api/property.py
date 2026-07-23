from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.models.user import User

from app.repositories.organization_repository import OrganizationRepository
from app.repositories.property_repository import PropertyRepository

from app.security.permissions import Permissions

from app.services.property_service import PropertyService

from app.schemas.property import (
    PropertyCreate,
    PropertyResponse,
)

router = APIRouter(
    prefix="/properties",
    tags=["Properties"],
)


def get_service(
    db: Session,
) -> PropertyService:

    return PropertyService(
        PropertyRepository(db),
        OrganizationRepository(db),
    )


@router.post(
    "",
    response_model=PropertyResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.PROPERTY_CREATE,
            )
        )
    ],
)
def create_property(
    property: PropertyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.create(
        current_user,
        property,
    )


@router.get(
    "",
    response_model=list[PropertyResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.PROPERTY_VIEW,
            )
        )
    ],
)
def get_properties(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.get_all(current_user)


@router.get(
    "/{property_id}",
    response_model=PropertyResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.PROPERTY_VIEW,
            )
        )
    ],
)
def get_property(
    property_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.get(
        current_user,
        property_id,
    )


@router.put(
    "/{property_id}",
    response_model=PropertyResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.PROPERTY_UPDATE,
            )
        )
    ],
)
def update_property(
    property_id: int,
    property: PropertyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.update(
        current_user,
        property_id,
        property,
    )


@router.delete(
    "/{property_id}",
    dependencies=[
        Depends(
            require_permission(
                Permissions.PROPERTY_DELETE,
            )
        )
    ],
)
def delete_property(
    property_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = get_service(db)

    service.delete(
        current_user,
        property_id,
    )

    return {
        "success": True,
        "message": "Property deleted successfully.",
    }