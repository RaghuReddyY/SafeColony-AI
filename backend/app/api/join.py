from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission

from app.database.dependency import get_db

from app.repositories.resident_repository import ResidentRepository
from app.repositories.unit_repository import UnitRepository

from app.schemas.join_request import (
    JoinOrganizationRequest,
    ApproveJoinRequest,
)

from app.security.permissions import Permissions

from app.services.join_service import JoinService


router = APIRouter(
    prefix="/join",
    tags=["Join Organization"],
)


def get_join_service(
    db: Session = Depends(get_db),
) -> JoinService:

    return JoinService(
        ResidentRepository(db),
        UnitRepository(db),
    )


# ==========================================================
# Resident submits join request
# ==========================================================

@router.post("")
def join_organization(
    request: JoinOrganizationRequest,
    current_user=Depends(get_current_user),
    service: JoinService = Depends(get_join_service),
):

    return service.join_organization(
        current_user,
        request,
    )


# ==========================================================
# Admin view pending requests
# ==========================================================

@router.get(
    "/pending",
    dependencies=[
        Depends(
            require_permission(
                Permissions.JOIN_REQUEST_VIEW
            )
        )
    ],
)
def pending_requests(
    service: JoinService = Depends(get_join_service),
):

    return service.get_pending()



# ==========================================================
# Admin approve request
# ==========================================================

@router.post(
    "/{request_id}/approve",
    dependencies=[
        Depends(
            require_permission(
                Permissions.JOIN_REQUEST_APPROVE
            )
        )
    ],
)
def approve_request(
    request_id: int,
    data: ApproveJoinRequest,
    service: JoinService = Depends(get_join_service),
):

    return service.approve(
        request_id,
        data.unit_id,
    )



# ==========================================================
# Admin reject request
# ==========================================================

@router.post(
    "/{request_id}/reject",
    dependencies=[
        Depends(
            require_permission(
                Permissions.JOIN_REQUEST_REJECT
            )
        )
    ],
)
def reject_request(
    request_id: int,
    service: JoinService = Depends(get_join_service),
):

    return service.reject(
        request_id
    )