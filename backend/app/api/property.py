from typing import Optional

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

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


def get_service(db: Session) -> PropertyService:
    property_repo = PropertyRepository(db)
    organization_repo = OrganizationRepository(db)

    return PropertyService(
        property_repo,
        organization_repo,
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
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.create(property)


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
    organization_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    service = get_service(db)

    if organization_id:
        return service.get_by_organization(
            organization_id
        )

    return service.get_all()


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
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.get(property_id)


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
    db: Session = Depends(get_db),
):
    service = get_service(db)

    return service.update(
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
    db: Session = Depends(get_db),
):
    service = get_service(db)

    service.delete(property_id)

    return {
        "success": True,
        "message": "Property deleted successfully.",
    }