from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.guard_repository import GuardRepository
from app.repositories.visitor_repository import VisitorRepository
from app.services.guard_service import GuardService
from app.services.visitor_service import VisitorService

router = APIRouter(
    prefix="/guard",
    tags=["Security Guard"],
)


# --------------------------------------------------------
# Request Models
# --------------------------------------------------------

class QRScanRequest(BaseModel):
    qr_token: str


class VisitorRequest(BaseModel):
    visitor_id: int


# --------------------------------------------------------
# Dashboard
# --------------------------------------------------------

@router.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
):
    repo = GuardRepository(db)
    service = GuardService(repo)

    return service.dashboard()


@router.get("/pending-visitors")
def pending_visitors(
    db: Session = Depends(get_db),
):
    repo = GuardRepository(db)
    service = GuardService(repo)

    return service.pending_visitors()


@router.get("/inside")
def visitors_inside(
    db: Session = Depends(get_db),
):
    repo = GuardRepository(db)
    service = GuardService(repo)

    return service.visitors_inside()


# --------------------------------------------------------
# QR Validation
# --------------------------------------------------------

@router.post("/validate-qr")
def validate_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.validate_qr(request.qr_token)


# --------------------------------------------------------
# Check In
# --------------------------------------------------------

@router.post("/check-in")
def check_in(
    request: VisitorRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.check_in(request.visitor_id)


# --------------------------------------------------------
# Check Out
# --------------------------------------------------------

@router.post("/check-out")
def check_out(
    request: VisitorRequest,
    db: Session = Depends(get_db),
):
    repo = VisitorRepository(db)
    service = VisitorService(repo)

    return service.check_out(request.visitor_id)