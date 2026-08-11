from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.schemas.visitor import VisitorCreate

from app.repositories.guard_repository import GuardRepository
from app.repositories.visitor_repository import VisitorRepository

from app.schemas.delivery import (
    GuardDeliveryResponse,
    VerifyOtpRequest,
)
from app.schemas.vehicle import VehicleResponse

from app.security.permissions import Permissions

from app.services.guard_service import GuardService
from app.services.visitor_service import VisitorService
from app.services.guard_lookup_service import GuardLookupService

from app.repositories.property_repository import PropertyRepository
from app.repositories.section_repository import SectionRepository
from app.repositories.unit_repository import UnitRepository
from app.repositories.resident_repository import ResidentRepository
from app.schemas.visitor import VisitorCreate, VisitorResponse

from app.schemas.guard_lookup import (
    GuardPropertyResponse,
    GuardSectionResponse,
    GuardUnitResponse,
    GuardResidentResponse,
)

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

def get_guard_lookup_service(
    db: Session = Depends(get_db),
) -> GuardLookupService:

    return GuardLookupService(
        PropertyRepository(db),
        SectionRepository(db),
        UnitRepository(db),
        ResidentRepository(db),
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
    response_model=list[GuardDeliveryResponse],
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
    response_model=GuardDeliveryResponse,
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
    response_model=GuardDeliveryResponse,
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

@router.get(
    "/properties",
    response_model=list[GuardPropertyResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_PROPERTY_VIEW,
            )
        )
    ],
)
def guard_properties(
    service: GuardLookupService = Depends(
        get_guard_lookup_service,
    ),
):
    return service.properties()

@router.get(
    "/sections/{property_id}",
    response_model=list[GuardSectionResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_SECTION_VIEW,
            )
        )
    ],
)
def guard_sections(
    property_id: int,
    service: GuardLookupService = Depends(
        get_guard_lookup_service,
    ),
):
    return service.sections(property_id)

@router.get(
    "/units/{section_id}",
    response_model=list[GuardUnitResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_UNIT_VIEW,
            )
        )
    ],
)
def guard_units(
    section_id: int,
    service: GuardLookupService = Depends(
        get_guard_lookup_service,
    ),
):
    return service.units(section_id)

@router.get(
    "/residents/{unit_id}",
    response_model=list[GuardResidentResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_RESIDENT_VIEW,
            )
        )
    ],
)
def guard_residents(
    unit_id: int,
    service: GuardLookupService = Depends(
        get_guard_lookup_service,
    ),
):
    return service.residents(unit_id)
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

@router.post(
    "/walk-in",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_WALKIN_VISITOR,
            )
        )
    ],
)
def create_walk_in_visitor(
    request: VisitorCreate,
    service: VisitorService = Depends(get_visitor_service),
):
    return service.create_walk_in(request)

@router.get(
    "/approved",
    dependencies=[
        Depends(
            require_permission(
                Permissions.GUARD_VISITOR_VIEW,
            )
        )
    ],
)
def approved_visitors(
    service: GuardService = Depends(
        get_guard_service,
    ),
):
    return service.approved_visitors()