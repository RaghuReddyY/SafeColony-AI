from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.repositories.resident_repository import ResidentRepository
from app.schemas.dashboard import ResidentDashboardResponse
from app.schemas.resident import (
    ResidentCreate,
    ResidentProfileResponse,
    ResidentProfileUpdate,
    ResidentResponse,
)
from app.security.permissions import Permissions
from app.services.resident_service import ResidentService
from app.enums import ResidentStatus

router = APIRouter(
    prefix="/residents",
    tags=["Residents"],
)


def get_resident_service(
    db: Session = Depends(get_db),
) -> ResidentService:
    repo = ResidentRepository(db)
    return ResidentService(repo)


@router.post(
    "",
    response_model=ResidentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Resident",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_CREATE,
            )
        )
    ],
)
def create_resident(
    resident: ResidentCreate,
    service: ResidentService = Depends(get_resident_service),
):
    return service.create(resident)


@router.get(
    "",
    response_model=list[ResidentResponse],
    summary="Get All Residents",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_VIEW,
            )
        )
    ],
)
def get_residents(
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_all()


@router.get(
    "/unit/{unit_id}",
    response_model=list[ResidentResponse],
    summary="Get Residents by Unit",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_VIEW,
            )
        )
    ],
)
def get_residents_by_unit(
    unit_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_by_unit(unit_id)


@router.get(
    "/dashboard/{resident_id}",
    response_model=ResidentDashboardResponse,
    summary="Resident Dashboard",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_DASHBOARD_VIEW,
            )
        )
    ],
)
def dashboard(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.dashboard(resident_id)


@router.get(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
    summary="Resident Profile",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_PROFILE_VIEW,
            )
        )
    ],
)
def get_profile(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_profile(resident_id)


@router.put(
    "/profile/{resident_id}",
    response_model=ResidentProfileResponse,
    summary="Update Resident Profile",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_PROFILE_UPDATE,
            )
        )
    ],
)
def update_profile(
    resident_id: int,
    resident: ResidentProfileUpdate,
    service: ResidentService = Depends(get_resident_service),
):
    return service.update_profile(
        resident_id,
        resident,
    )


@router.get(
    "/dropdown",
    summary="Resident Dropdown",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_VIEW,
            )
        )
    ],
)
def resident_dropdown(
    service: ResidentService = Depends(get_resident_service),
):
    return service.dropdown()

@router.get(
    "/pending",
    response_model=list[ResidentResponse],
    summary="Get Pending Residents",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_APPROVE,
            )
        )
    ],
)
def get_pending_residents(
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_pending()


@router.post(
    "/{resident_id}/approve",
    response_model=ResidentResponse,
    summary="Approve Resident",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_APPROVE,
            )
        )
    ],
)
def approve_resident(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.approve(resident_id)


@router.post(
    "/{resident_id}/reject",
    response_model=ResidentResponse,
    summary="Reject Resident",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_APPROVE,
            )
        )
    ],
)
def reject_resident(
    resident_id: int,
    service: ResidentService = Depends(get_resident_service),
):
    return service.reject(resident_id)