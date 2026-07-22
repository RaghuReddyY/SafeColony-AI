from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.guard_repository import GuardRepository
from app.repositories.visitor_repository import VisitorRepository

from app.schemas.delivery import (
    DeliveryResponse,
    VerifyOtpRequest,
)
from app.schemas.vehicle import VehicleResponse

from app.security.permissions import Permissions

from app.services.guard_service import GuardService
from app.services.visitor_service import VisitorService

router = APIRouter(
    prefix="/guard",
    tags=["Security Guard"],
)


# ==========================================================
# Request Models
# ==========================================================

class QRScanRequest(BaseModel):
    qr_token: str


class VisitorRequest(BaseModel):
    visitor_id: int


class DeliveryReceiveRequest(BaseModel):
    guard_name: str


class VehicleGuardRequest(BaseModel):
    guard_name: str


# ==========================================================
# Dependencies
# ==========================================================

def get_guard_service(
    db: Session = Depends(get_db),
) -> GuardService:
    return GuardService(
        GuardRepository(db)
    )


def get_visitor_service(
    db: Session = Depends(get_db),
) -> VisitorService:
    return VisitorService(
        VisitorRepository(db)
    )


# ==========================================================
# Dashboard
# ==========================================================

@router.get(
    "/dashboard",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_DASHBOARD,
            )
        )
    ],
)
def dashboard(
    service: GuardService = Depends(get_guard_service),
):
    return service.dashboard()


# ==========================================================
# Visitors
# ==========================================================

@router.get(
    "/pending-visitors",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VISITOR_VIEW,
            )
        )
    ],
)
def pending_visitors(
    service: GuardService = Depends(get_guard_service),
):
    return service.pending_visitors()


@router.get(
    "/inside",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VISITOR_VIEW,
            )
        )
    ],
)
def visitors_inside(
    service: GuardService = Depends(get_guard_service),
):
    return service.visitors_inside()


# ==========================================================
# Deliveries
# ==========================================================

@router.get(
    "/pending-deliveries",
    response_model=list[DeliveryResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_DELIVERY_VIEW,
            )
        )
    ],
)
def pending_deliveries(
    service: GuardService = Depends(get_guard_service),
):
    return service.pending_deliveries()


@router.post(
    "/receive-delivery/{delivery_id}",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_DELIVERY_RECEIVE,
            )
        )
    ],
)
def receive_delivery(
    delivery_id: int,
    request: DeliveryReceiveRequest,
    service: GuardService = Depends(get_guard_service),
):
    return service.receive_delivery(
        delivery_id,
        request.guard_name,
    )


@router.post(
    "/verify-delivery/{delivery_id}",
    response_model=DeliveryResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_DELIVERY_VERIFY,
            )
        )
    ],
)
def verify_delivery(
    delivery_id: int,
    request: VerifyOtpRequest,
    service: GuardService = Depends(get_guard_service),
):
    return service.verify_delivery(
        delivery_id,
        request.otp,
    )


# ==========================================================
# Vehicles
# ==========================================================

@router.get(
    "/pending-vehicles",
    response_model=list[VehicleResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VEHICLE_VIEW,
            )
        )
    ],
)
def pending_vehicles(
    service: GuardService = Depends(get_guard_service),
):
    return service.pending_vehicles()


@router.post(
    "/vehicle-entry/{vehicle_id}",
    response_model=VehicleResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VEHICLE_ENTRY,
            )
        )
    ],
)
def vehicle_entry(
    vehicle_id: int,
    request: VehicleGuardRequest,
    service: GuardService = Depends(get_guard_service),
):
    return service.vehicle_entry(
        vehicle_id,
        request.guard_name,
    )


@router.post(
    "/vehicle-exit/{vehicle_id}",
    response_model=VehicleResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VEHICLE_EXIT,
            )
        )
    ],
)
def vehicle_exit(
    vehicle_id: int,
    request: VehicleGuardRequest,
    service: GuardService = Depends(get_guard_service),
):
    return service.vehicle_exit(
        vehicle_id,
        request.guard_name,
    )


# ==========================================================
# Visitor QR
# ==========================================================

@router.post(
    "/validate-qr",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_QR_SCAN,
            )
        )
    ],
)
def validate_qr(
    request: QRScanRequest,
    service: VisitorService = Depends(get_visitor_service),
):
    return service.validate_qr(
        request.qr_token,
    )


@router.post(
    "/check-in",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VISITOR_CHECKIN,
            )
        )
    ],
)
def check_in(
    request: VisitorRequest,
    service: VisitorService = Depends(get_visitor_service),
):
    return service.check_in(
        request.visitor_id,
    )


@router.post(
    "/check-out",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VISITOR_CHECKOUT,
            )
        )
    ],
)
def check_out(
    request: VisitorRequest,
    service: VisitorService = Depends(get_visitor_service),
):
    return service.check_out(
        request.visitor_id,
    )