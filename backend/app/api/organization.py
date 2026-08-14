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
    GuardCreate,
    GuardResponse,
    BlockAdminCreate,
    FinanceAdminCreate,
    ScopedAdminResponse,
    BlockScopeResponse,
)
from app.auth.dependencies import get_current_user
from app.models.user import User
from app.models.section import Section
from app.models.property import Property

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

# ==========================================================
# Guard Management
# ==========================================================

@router.post(
    "/guards",
    response_model=GuardResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.ORGANIZATION_CREATE,
            )
        )
    ],
)
def create_guard(
    guard: GuardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrganizationService(db)

    return service.create_guard(
        current_user,
        guard,
    )


@router.get(
    "/guards",
    response_model=list[GuardResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.ORGANIZATION_VIEW,
            )
        )
    ],
)
def get_guards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrganizationService(db)

    return service.get_guards(current_user)
# ==========================================================
# Block Admin / Community Finance Collector
# ==========================================================

@router.post(
    "/block-admins",
    response_model=ScopedAdminResponse,
    dependencies=[Depends(require_permission(Permissions.BLOCK_ADMIN_MANAGE))],
)
def create_block_admin(
    data: BlockAdminCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrganizationService(db)
    user = service.create_block_admin(current_user, data)
    scopes = service.get_scoped_admins(current_user)
    return next(item for item in scopes if item["id"] == user.id)


@router.post(
    "/finance-admins",
    response_model=ScopedAdminResponse,
    dependencies=[Depends(require_permission(Permissions.BLOCK_ADMIN_MANAGE))],
)
def create_finance_admin(
    data: FinanceAdminCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrganizationService(db)
    user = service.create_finance_admin(current_user, data)
    scopes = service.get_scoped_admins(current_user)
    return next(item for item in scopes if item["id"] == user.id)


@router.get(
    "/scoped-admins",
    response_model=list[ScopedAdminResponse],
    dependencies=[Depends(require_permission(Permissions.BLOCK_ADMIN_VIEW))],
)
def get_scoped_admins(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return OrganizationService(db).get_scoped_admins(current_user)


@router.get(
    "/blocks",
    response_model=list[BlockScopeResponse],
    dependencies=[Depends(require_permission(Permissions.BLOCK_ADMIN_VIEW))],
)
def get_blocks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = (
        db.query(Section)
        .join(Property, Section.property_id == Property.id)
        .filter(Property.organization_id == current_user.organization_id)
        .order_by(Section.name.asc())
        .all()
    )
    return [
        {
            "section_id": row.id,
            "section_name": row.name,
            "property_id": row.property_id,
        }
        for row in rows
    ]

@router.get(
    "/my-blocks",
    response_model=list[BlockScopeResponse],
    dependencies=[Depends(require_permission(Permissions.BLOCK_ADMIN_VIEW))],
)
def get_my_blocks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.models.user_block_scope import UserBlockScope
    rows = (
        db.query(Section)
        .join(UserBlockScope, UserBlockScope.section_id == Section.id)
        .join(Property, Section.property_id == Property.id)
        .filter(
            UserBlockScope.user_id == current_user.id,
            Property.organization_id == current_user.organization_id,
        )
        .order_by(Section.name.asc())
        .all()
    )
    return [
        {"section_id": row.id, "section_name": row.name, "property_id": row.property_id}
        for row in rows
    ]
