from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.organization_repository import OrganizationRepository
from app.services.organization_service import OrganizationService

from app.schemas.organization import (
    OrganizationCreate,
    OrganizationResponse,
)

router = APIRouter(
    prefix="/organizations",
    tags=["Organizations"],
)


@router.post(
    "",
    response_model=OrganizationResponse,
)
def create_organization(
    organization: OrganizationCreate,
    db: Session = Depends(get_db),
):

    repo = OrganizationRepository(db)

    service = OrganizationService(repo)

    return service.create(organization)


@router.get(
    "",
    response_model=list[OrganizationResponse],
)
def get_organizations(
    db: Session = Depends(get_db),
):

    repo = OrganizationRepository(db)

    service = OrganizationService(repo)

    return service.get_all()