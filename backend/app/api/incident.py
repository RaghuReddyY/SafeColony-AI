from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.repositories.incident_repository import IncidentRepository
from app.schemas.incident import (
    IncidentCreate, IncidentUpdate, IncidentEvidenceCreate,
    IncidentResponse, IncidentEvidenceResponse, IncidentReportResponse,
)
from app.security.permissions import Permissions
from app.services.incident_service import IncidentService

router = APIRouter(prefix="/incidents", tags=["Incident Management"])


def get_service(db: Session = Depends(get_db)):
    return IncidentService(IncidentRepository(db))


@router.post("", response_model=IncidentResponse, dependencies=[Depends(require_permission(Permissions.INCIDENT_CREATE))])
def create(data: IncidentCreate, current_user: User = Depends(get_current_user), service: IncidentService = Depends(get_service)):
    return service.create(current_user, data)


@router.get("", response_model=list[IncidentResponse], dependencies=[Depends(require_permission(Permissions.INCIDENT_VIEW))])
def list_incidents(status: str | None = None, current_user: User = Depends(get_current_user), service: IncidentService = Depends(get_service)):
    return service.list(current_user, status)


@router.get("/report", response_model=IncidentReportResponse, dependencies=[Depends(require_permission(Permissions.INCIDENT_VIEW))])
def report(current_user: User = Depends(get_current_user), service: IncidentService = Depends(get_service)):
    return service.report(current_user)


@router.put("/{incident_id}", response_model=IncidentResponse, dependencies=[Depends(require_permission(Permissions.INCIDENT_MANAGE))])
def update(incident_id: int, data: IncidentUpdate, current_user: User = Depends(get_current_user), service: IncidentService = Depends(get_service)):
    return service.update(current_user, incident_id, data)


@router.post("/{incident_id}/evidence/photo", response_model=IncidentEvidenceResponse, dependencies=[Depends(require_permission(Permissions.INCIDENT_EVIDENCE))])
async def add_photo(
    incident_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    service: IncidentService = Depends(get_service),
):
    return await service.add_photo(current_user, incident_id, file)


@router.post("/{incident_id}/evidence", response_model=IncidentEvidenceResponse, dependencies=[Depends(require_permission(Permissions.INCIDENT_EVIDENCE))])
def add_evidence(
    incident_id: int,
    data: IncidentEvidenceCreate,
    current_user: User = Depends(get_current_user),
    service: IncidentService = Depends(get_service),
):
    return service.add_evidence(current_user, incident_id, data)
