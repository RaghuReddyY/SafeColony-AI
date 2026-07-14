from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependency import get_db
from app.repositories.guard_repository import GuardRepository
from app.services.guard_service import GuardService

router = APIRouter(
    prefix="/guard",
    tags=["Security Guard"],
)


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