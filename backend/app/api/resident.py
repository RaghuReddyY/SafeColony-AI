from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.dashboard import ResidentDashboardResponse
from app.schemas.resident import (
    ResidentCreate,
    ResidentProfileResponse,
    ResidentProfileUpdate,
    ResidentResponse,
)
from app.security.permissions import Permissions
from app.services.resident_service import ResidentService

router = APIRouter(
    prefix="/residents",
    tags=["Residents"],
)


def get_resident_service(
    db: Session = Depends(get_db),
) -> ResidentService:
    return ResidentService(db)


@router.post(
    "",
    response_model=ResidentResponse,
    status_code=status.HTTP_201_CREATED,
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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.create(
        user_id=resident.user_id,
        unit_id=resident.unit_id,
        resident_type=resident.resident_type,
        gender=resident.gender,
        date_of_birth=resident.date_of_birth,
        emergency_contact=resident.emergency_contact,
        emergency_contact_name=resident.emergency_contact_name,
        is_primary=resident.is_primary,
        current_user=current_user,
    )


@router.get(
    "",
    response_model=list[ResidentResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_VIEW,
            )
        )
    ],
)
def get_residents(
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_all(current_user)


@router.get(
    "/unit/{unit_id}",
    response_model=list[ResidentResponse],
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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_by_unit(
        unit_id,
        current_user,
    )
@router.get(
    "/dashboard",
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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_dashboard(current_user)


@router.get(
    "/profile",
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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_profile(current_user)


@router.put(
    "/profile",
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
    resident: ResidentProfileUpdate,
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.update_profile(
        resident,
        current_user,
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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.dropdown(current_user)


@router.get(
    "/pending",
    response_model=list[ResidentResponse],
    summary="Pending Residents",
    dependencies=[
        Depends(
            require_permission(
                Permissions.RESIDENT_APPROVE,
            )
        )
    ],
)
def get_pending_residents(
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.get_pending(current_user)


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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.approve(
        resident_id,
        current_user,
    )


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
    current_user: User = Depends(get_current_user),
    service: ResidentService = Depends(get_resident_service),
):
    return service.reject(
        resident_id,
        current_user,
    )