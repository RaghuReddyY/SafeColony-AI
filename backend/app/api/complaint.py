from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.complaint_repository import ComplaintRepository
from app.schemas.complaint import ComplaintCreate, ComplaintUpdate, ComplaintEscalate, ComplaintResponse
from app.security.permissions import Permissions
from app.services.complaint_service import ComplaintService

router = APIRouter(prefix="/complaints", tags=["Complaint Management"])


def get_service(db: Session = Depends(get_db)):
    return ComplaintService(ComplaintRepository(db))


@router.post("", response_model=ComplaintResponse, dependencies=[Depends(require_permission(Permissions.COMPLAINT_CREATE))])
def create(data: ComplaintCreate, current_user: User = Depends(get_current_user), service: ComplaintService = Depends(get_service)):
    return service.create(current_user, data)


@router.get("", response_model=list[ComplaintResponse], dependencies=[Depends(require_permission(Permissions.COMPLAINT_VIEW))])
def list_complaints(status: str | None = None, current_user: User = Depends(get_current_user), service: ComplaintService = Depends(get_service)):
    return service.list(current_user, status)


@router.get("/{complaint_id}", response_model=ComplaintResponse, dependencies=[Depends(require_permission(Permissions.COMPLAINT_VIEW))])
def get(complaint_id: int, current_user: User = Depends(get_current_user), service: ComplaintService = Depends(get_service)):
    return service.get(current_user, complaint_id)


@router.put("/{complaint_id}", response_model=ComplaintResponse, dependencies=[Depends(require_permission(Permissions.COMPLAINT_MANAGE))])
def update(complaint_id: int, data: ComplaintUpdate, current_user: User = Depends(get_current_user), service: ComplaintService = Depends(get_service)):
    return service.update(current_user, complaint_id, data)


@router.post("/{complaint_id}/escalate", response_model=ComplaintResponse, dependencies=[Depends(require_permission(Permissions.COMPLAINT_ESCALATE))])
def escalate(complaint_id: int, data: ComplaintEscalate, current_user: User = Depends(get_current_user), service: ComplaintService = Depends(get_service)):
    return service.escalate(current_user, complaint_id, data)
