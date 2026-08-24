from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.marketplace import (
    EventAggregateResponse, EventCreate, EventResponse, EventStatusUpdate, OrderCreate, OrderResponse,
    VendorCreate, VendorResponse, VendorDashboardResponse, VendorEventResponse, VendorProfileUpdate, VendorOfferCreate, VendorOfferResponse, VendorAccountCreate, VendorAccountResponse,
)
from app.security.permissions import Permissions
from app.services.marketplace_service import MarketplaceService

router = APIRouter(prefix="/marketplace", tags=["Community Marketplace"])


def svc(db: Session = Depends(get_db)) -> MarketplaceService:
    return MarketplaceService(db)


@router.get("/events", response_model=list[EventResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VIEW))])
def events(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.list_events(current_user)


@router.post("/events", response_model=EventResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def create_event(data: EventCreate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.create_event(current_user, data)


@router.get("/vendors", response_model=list[VendorResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def vendors(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.list_vendors(current_user)


@router.post("/vendors", response_model=VendorResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def create_vendor(data: VendorCreate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.create_vendor(current_user, data)


@router.post("/vendor-accounts", response_model=VendorAccountResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def create_vendor_account(data: VendorAccountCreate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.create_vendor_account(current_user, data)


@router.post("/events/{event_id}/orders", response_model=OrderResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_ORDER))])
def place_order(event_id: int, data: OrderCreate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.place_order(current_user, event_id, data)


@router.get("/my-orders", response_model=list[OrderResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_ORDER))])
def my_orders(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.my_orders(current_user)




@router.get("/vendor/dashboard", response_model=VendorDashboardResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_dashboard(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.vendor_dashboard(current_user)


@router.get("/vendor/events", response_model=list[VendorEventResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_events(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.vendor_events(current_user)


@router.get("/vendor/events/{event_id}/aggregate", response_model=EventAggregateResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_event_aggregate(event_id: int, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.vendor_aggregate(current_user, event_id)


@router.patch("/vendor/events/{event_id}/status", response_model=VendorEventResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_event_status(event_id: int, data: EventStatusUpdate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.update_vendor_event_status(current_user, event_id, data.status)


@router.patch("/vendor/profile", response_model=VendorResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_profile(data: VendorProfileUpdate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.update_vendor_profile(current_user, data)

@router.get("/vendor/offers", response_model=list[VendorOfferResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_offers(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.vendor_offers(current_user)


@router.post("/vendor/offers", response_model=VendorOfferResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def create_vendor_offer(data: VendorOfferCreate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.create_vendor_offer(current_user, data)


@router.get("/vendor/orders", response_model=list[OrderResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def vendor_orders(current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.vendor_orders(current_user)


@router.patch("/vendor/orders/{order_id}", response_model=OrderResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VENDOR))])
def update_vendor_order(order_id: int, status: str, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.update_vendor_order(current_user, order_id, status)


@router.get("/events/{event_id}/aggregate", response_model=EventAggregateResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_VIEW))])
def aggregate(event_id: int, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.aggregate(current_user, event_id)


@router.patch("/events/{event_id}/status", response_model=EventResponse, dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def update_event_status(event_id: int, data: EventStatusUpdate, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.update_event_status(current_user, event_id, data.status)


@router.get("/orders", response_model=list[OrderResponse], dependencies=[Depends(require_permission(Permissions.MARKETPLACE_MANAGE))])
def admin_orders(event_id: int | None = None, current_user: User = Depends(get_current_user), service: MarketplaceService = Depends(svc)):
    return service.admin_orders(current_user, event_id)
