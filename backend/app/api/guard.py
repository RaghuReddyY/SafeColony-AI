from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database.dependency import get_db

from app.repositories.guard_repository import GuardRepository
from app.repositories.visitor_repository import VisitorRepository

from app.services.guard_service import GuardService
from app.services.visitor_service import VisitorService

from app.schemas.delivery import (
    DeliveryResponse,
    VerifyOtpRequest,
)

from app.schemas.vehicle import VehicleResponse

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
# Dashboard
# ==========================================================

@router.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.dashboard()


# ==========================================================
# Visitors
# ==========================================================

@router.get("/pending-visitors")
def pending_visitors(
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.pending_visitors()


@router.get("/inside")
def visitors_inside(
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.visitors_inside()


# ==========================================================
# Deliveries
# ==========================================================

@router.get(
    "/pending-deliveries",
    response_model=list[DeliveryResponse],
)
def pending_deliveries(
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.pending_deliveries()


@router.post(
    "/receive-delivery/{delivery_id}",
    response_model=DeliveryResponse,
)
def receive_delivery(
    delivery_id: int,
    request: DeliveryReceiveRequest,
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.receive_delivery(
        delivery_id,
        request.guard_name,
    )


@router.post(
    "/verify-delivery/{delivery_id}",
    response_model=DeliveryResponse,
)
def verify_delivery(
    delivery_id: int,
    request: VerifyOtpRequest,
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.verify_delivery(
        delivery_id,
        request.otp,
    )


# ==========================================================
# Vehicle Operations
# ==========================================================

@router.get(
    "/pending-vehicles",
    response_model=list[VehicleResponse],
)
def pending_vehicles(
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.pending_vehicles()


@router.post(
    "/vehicle-entry/{vehicle_id}",
    response_model=VehicleResponse,
)
def vehicle_entry(
    vehicle_id: int,
    request: VehicleGuardRequest,
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.vehicle_entry(
        vehicle_id,
        request.guard_name,
    )


@router.post(
    "/vehicle-exit/{vehicle_id}",
    response_model=VehicleResponse,
)
def vehicle_exit(
    vehicle_id: int,
    request: VehicleGuardRequest,
    db: Session = Depends(get_db),
):

    service = GuardService(
        GuardRepository(db)
    )

    return service.vehicle_exit(
        vehicle_id,
        request.guard_name,
    )


# ==========================================================
# Visitor QR
# ==========================================================

@router.post("/validate-qr")
def validate_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
):

    repo = VisitorRepository(db)

    service = VisitorService(repo)

    return service.validate_qr(
        request.qr_token
    )


@router.post("/check-in")
def check_in(
    request: VisitorRequest,
    db: Session = Depends(get_db),
):

    repo = VisitorRepository(db)

    service = VisitorService(repo)

    return service.check_in(
        request.visitor_id
    )


@router.post("/check-out")
def check_out(
    request: VisitorRequest,
    db: Session = Depends(get_db),
):

    repo = VisitorRepository(db)

    service = VisitorService(repo)

    return service.check_out(
        request.visitor_id
    )