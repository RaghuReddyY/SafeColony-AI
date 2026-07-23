from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.schemas.public import (
    PublicOrganizationResponse,
    PublicSectionResponse,
)
from app.services.public_service import PublicService

router = APIRouter(
    prefix="/public",
    tags=["Public"],
)


@router.get(
    "/organization/{organization_code}",
    response_model=PublicOrganizationResponse,
)
def get_organization(
    organization_code: str,
    db: Session = Depends(get_db),
):
    service = PublicService(db)

    try:
        return service.get_organization(organization_code)
    except ValueError as ex:
        raise HTTPException(
            status_code=404,
            detail=str(ex),
        )


@router.get(
    "/properties/{property_id}/sections",
    response_model=list[PublicSectionResponse],
)
def get_sections(
    property_id: int,
    db: Session = Depends(get_db),
):
    service = PublicService(db)

    return service.get_sections(property_id)