from fastapi import APIRouter, Depends

from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.property_repository import PropertyRepository

from app.services.property_service import PropertyService

from app.schemas.property import (
    PropertyCreate,
    PropertyResponse,
)

router = APIRouter(
    prefix="/properties",
    tags=["Properties"],
)


@router.post(
    "",
    response_model=PropertyResponse,
)
def create_property(
    property: PropertyCreate,
    db: Session = Depends(get_db),
):

    repo = PropertyRepository(db)

    service = PropertyService(repo)

    return service.create(property)


@router.get(
    "",
    response_model=list[PropertyResponse],
)
def get_properties(
    db: Session = Depends(get_db),
):

    repo = PropertyRepository(db)

    service = PropertyService(repo)

    return service.get_all()


@router.get(
    "/{property_id}",
    response_model=PropertyResponse,
)
def get_property(
    property_id: int,
    db: Session = Depends(get_db),
):

    repo = PropertyRepository(db)

    service = PropertyService(repo)

    return service.get(property_id)