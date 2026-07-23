from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.security.permissions import Permissions
from app.services.organization_service import OrganizationService

from app.schemas.organization import (
    OrganizationCreate,
    OrganizationOnboardRequest,
    OrganizationOnboardResponse,
    OrganizationResponse,
)

router = APIRouter(
    prefix="/organizations",
    tags=["Organizations"],
)


# ==========================================================
# Public Organization Registration
# ==========================================================

@router.post(
    "/register",
    response_model=OrganizationOnboardResponse,
)
def register_organization(
    request: OrganizationOnboardRequest,
    db: Session = Depends(get_db),
):
    service = OrganizationService(db)

    return service.onboard(request)


# ==========================================================
# Create Organization (Internal)
# ==========================================================

@router.post(
    "",
    response_model=OrganizationResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.ORGANIZATION_CREATE,
            )
        )
    ],
)
def create_organization(
    organization: OrganizationCreate,
    db: Session = Depends(get_db),
):
    service = OrganizationService(db)

    return service.create(organization)


# ==========================================================
# List Organizations
# ==========================================================

@router.get(
    "",
    response_model=list[OrganizationResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.ORGANIZATION_VIEW,
            )
        )
    ],
)
def get_organizations(
    db: Session = Depends(get_db),
):
    service = OrganizationService(db)

    return service.get_all()


# ==========================================================
# Internal Onboard API (Optional)
# ==========================================================

@router.post(
    "/onboard",
    response_model=OrganizationOnboardResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.ORGANIZATION_CREATE,
            )
        )
    ],
)
def onboard_organization(
    request: OrganizationOnboardRequest,
    db: Session = Depends(get_db),
):
    service = OrganizationService(db)

    return service.onboard(request)