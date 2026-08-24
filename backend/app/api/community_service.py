from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.community_service_repository import CommunityServiceRepository
from app.schemas.community_service import (
    CommunityServiceCreate,
    CommunityServiceResponse,
    CommunityServiceUpdate,
)
from app.security.permissions import Permissions
from app.services.community_service_service import CommunityServiceService


router = APIRouter(prefix="/community-services", tags=["Community Services"])


def get_service(db: Session = Depends(get_db)) -> CommunityServiceService:
    return CommunityServiceService(CommunityServiceRepository(db))


@router.get(
    "",
    response_model=list[CommunityServiceResponse],
    dependencies=[Depends(require_permission(Permissions.COMMUNITY_SERVICE_VIEW))],
)
def list_community_services(
    category: str | None = None,
    current_user: User = Depends(get_current_user),
    service: CommunityServiceService = Depends(get_service),
):
    if current_user.organization_id is None:
        return []
    return service.list(current_user.organization_id, category)


@router.post(
    "",
    response_model=CommunityServiceResponse,
    dependencies=[Depends(require_permission(Permissions.COMMUNITY_SERVICE_CREATE))],
)
def create_community_service(
    data: CommunityServiceCreate,
    current_user: User = Depends(get_current_user),
    service: CommunityServiceService = Depends(get_service),
):
    if current_user.organization_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User is not associated with an organization.")
    return service.create(data, current_user.organization_id, current_user.id)


@router.patch(
    "/{service_id}",
    response_model=CommunityServiceResponse,
    dependencies=[Depends(require_permission(Permissions.COMMUNITY_SERVICE_UPDATE))],
)
def update_community_service(
    service_id: int,
    data: CommunityServiceUpdate,
    current_user: User = Depends(get_current_user),
    service: CommunityServiceService = Depends(get_service),
):
    if current_user.organization_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User is not associated with an organization.")
    return service.update(service_id, data, current_user.organization_id, current_user.id)
