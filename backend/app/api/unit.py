from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.unit_repository import UnitRepository

from app.schemas.unit import (
    UnitCreate,
    UnitResponse,
    UnitUpdate,
)

from app.security.permissions import Permissions
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
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_CREATE
            )
        )
    ],
)
def create_unit(
    unit: UnitCreate,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.create(unit)



@router.get(
    "",
    response_model=list[UnitResponse],
    summary="Get All Units",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_VIEW
            )
        )
    ],
)
def get_units(
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.get_all()



@router.get(
    "/{unit_id}",
    response_model=UnitResponse,
    summary="Get Unit",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_VIEW
            )
        )
    ],
)
def get_unit(
    unit_id: int,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.get(unit_id)



@router.get(
    "/section/{section_id}",
    response_model=list[UnitResponse],
    summary="Get Units by Section",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_VIEW
            )
        )
    ],
)
def get_units_by_section(
    section_id: int,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.get_by_section(
        section_id
    )



@router.get(
    "/property/{property_id}",
    response_model=list[UnitResponse],
    summary="Get Units by Property",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_VIEW
            )
        )
    ],
)
def get_units_by_property(
    property_id: int,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.get_by_property(
        property_id
    )



@router.put(
    "/{unit_id}",
    response_model=UnitResponse,
    summary="Update Unit",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_UPDATE
            )
        )
    ],
)
def update_unit(
    unit_id: int,
    unit: UnitUpdate,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    return service.update(
        unit_id,
        unit,
    )



@router.delete(
    "/{unit_id}",
    summary="Delete Unit",
    dependencies=[
        Depends(
            require_permission(
                Permissions.UNIT_DELETE
            )
        )
    ],
)
def delete_unit(
    unit_id: int,
    service: UnitService = Depends(
        get_unit_service
    ),
):

    service.delete(unit_id)

    return {
        "success": True,
        "message": "Unit deleted successfully",
    }