from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.permissions import require_permission
from app.database.dependency import get_db

from app.repositories.visitor_repository import VisitorRepository
from app.security.permissions import Permissions
from app.services.visitor_service import VisitorService

from app.schemas.visitor import (
    VisitorCreate,
    VisitorResponse,
)

from app.schemas.scan import (
    QRScanRequest,
    QRScanResponse,
)

router = APIRouter(
    prefix="/visitors",
    tags=["Visitors"],
)


@router.post(
    "",
    response_model=VisitorResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_CREATE,
            )
        )
    ],
)
def create_visitor(
    visitor: VisitorCreate,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.create(visitor)


@router.get(
    "",
    response_model=list[VisitorResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_VIEW,
            )
        )
    ],
)
def get_visitors(
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.get_all()


@router.get(
    "/resident/{resident_id}",
    response_model=list[VisitorResponse],
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_VIEW,
            )
        )
    ],
)
def get_visitors_by_resident(
    resident_id: int,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.get_by_resident(resident_id)


@router.post(
    "/{visitor_id}/approve",
    response_model=VisitorResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_APPROVE,
            )
        )
    ],
)
def approve_visitor(
    visitor_id: int,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.approve(visitor_id)


@router.post(
    "/{visitor_id}/reject",
    response_model=VisitorResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_REJECT,
            )
        )
    ],
)
def reject_visitor(
    visitor_id: int,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.reject(visitor_id)


@router.post(
    "/{visitor_id}/check-in",
    response_model=VisitorResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_CHECKIN,
            )
        )
    ],
)
def check_in_visitor(
    visitor_id: int,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.check_in(visitor_id)


@router.post(
    "/{visitor_id}/check-out",
    response_model=VisitorResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_CHECKOUT,
            )
        )
    ],
)
def check_out_visitor(
    visitor_id: int,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.check_out(visitor_id)


@router.post(
    "/validate-qr",
    response_model=QRScanResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_QR_VALIDATE,
            )
        )
    ],
)
def validate_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    visitor = service.validate_qr(request.qr_token)

    return QRScanResponse(
        id=visitor.id,
        visitor_name=visitor.visitor_name,
        resident_id=visitor.resident_id,
        phone=visitor.phone,
        visitor_type=visitor.visitor_type,
        purpose=visitor.purpose,
        vehicle_number=visitor.vehicle_number,
        status=visitor.status,
    )


@router.post(
    "/scan",
    response_model=QRScanResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_QR_SCAN,
            )
        )
    ],
)
def scan_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    visitor = service.scan_qr(request.qr_token)

    return QRScanResponse(
        id=visitor.id,
        visitor_name=visitor.visitor_name,
        resident_id=visitor.resident_id,
        phone=visitor.phone,
        visitor_type=visitor.visitor_type,
        purpose=visitor.purpose,
        vehicle_number=visitor.vehicle_number,
        status=visitor.status,
    )


@router.post(
    "/scan-exit",
    response_model=QRScanResponse,
    dependencies=[
        Depends(
            require_permission(
                Permissions.VISITOR_QR_EXIT,
            )
        )
    ],
)
def scan_exit(
    request: QRScanRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    visitor = service.scan_exit(request.qr_token)

    return QRScanResponse(
        id=visitor.id,
        visitor_name=visitor.visitor_name,
        resident_id=visitor.resident_id,
        phone=visitor.phone,
        visitor_type=visitor.visitor_type,
        purpose=visitor.purpose,
        vehicle_number=visitor.vehicle_number,
        status=visitor.status,
    )