from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.amenity_repository import AmenityRepository
from app.schemas.amenity import (
    AmenityCreate, AmenityUpdate, AmenityResponse,
    AmenityBookingCreate, AmenityBookingDecision, AmenityBookingResponse,
)
from app.security.permissions import Permissions
from app.services.amenity_service import AmenityService

router = APIRouter(prefix="/amenities", tags=["Amenities"])


def get_service(db: Session = Depends(get_db)):
    return AmenityService(AmenityRepository(db))


@router.get("", response_model=list[AmenityResponse], dependencies=[Depends(require_permission(Permissions.AMENITY_VIEW))])
def list_amenities(current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.list_amenities(current_user)


@router.post("", response_model=AmenityResponse, dependencies=[Depends(require_permission(Permissions.AMENITY_MANAGE))])
def create_amenity(data: AmenityCreate, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.create_amenity(current_user, data)


@router.put("/{amenity_id}", response_model=AmenityResponse, dependencies=[Depends(require_permission(Permissions.AMENITY_MANAGE))])
def update_amenity(amenity_id: int, data: AmenityUpdate, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.update_amenity(current_user, amenity_id, data)


@router.post("/bookings", response_model=AmenityBookingResponse, dependencies=[Depends(require_permission(Permissions.AMENITY_BOOK))])
def create_booking(data: AmenityBookingCreate, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.create_booking(current_user, data)


@router.get("/bookings", response_model=list[AmenityBookingResponse], dependencies=[Depends(require_permission(Permissions.AMENITY_VIEW))])
def list_bookings(status: str | None = None, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.list_bookings(current_user, status)


@router.post("/bookings/{booking_id}/decision", response_model=AmenityBookingResponse, dependencies=[Depends(require_permission(Permissions.AMENITY_APPROVE))])
def decide_booking(booking_id: int, data: AmenityBookingDecision, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.decide(current_user, booking_id, data)


@router.post("/bookings/{booking_id}/cancel", response_model=AmenityBookingResponse, dependencies=[Depends(require_permission(Permissions.AMENITY_BOOK))])
def cancel_booking(booking_id: int, current_user: User = Depends(get_current_user), service: AmenityService = Depends(get_service)):
    return service.cancel(current_user, booking_id)
