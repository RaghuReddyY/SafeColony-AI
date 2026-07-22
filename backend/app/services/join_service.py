from fastapi import HTTPException, status

from app.enums import (
    ResidentStatus,
    JoinStatus,
)

from app.models.join_request import JoinRequest
from app.repositories.resident_repository import ResidentRepository
from app.repositories.unit_repository import UnitRepository



class JoinService:


    def __init__(
        self,
        resident_repo: ResidentRepository,
        unit_repo: UnitRepository,
    ):

        self.resident_repo = resident_repo
        self.unit_repo = unit_repo
        self.db = resident_repo.db



    # Resident submits request

    def join_organization(
        self,
        current_user,
        request,
    ):

        resident = self.resident_repo.get_by_user_id(
            current_user.id
        )


        if resident is None:

            raise HTTPException(
                status_code=404,
                detail="Resident profile not found.",
            )


        existing = (
            self.db.query(JoinRequest)
            .filter(
                JoinRequest.user_id == current_user.id,
                JoinRequest.status == JoinStatus.PENDING,
            )
            .first()
        )


        if existing:

            raise HTTPException(
                status_code=409,
                detail="Join request already pending.",
            )


        join_request = JoinRequest(

            user_id=current_user.id,

            organization_id=request.organization_id,

            status=JoinStatus.PENDING,
        )


        self.db.add(join_request)

        self.db.commit()

        self.db.refresh(join_request)


        return {

            "message":
            "Join request submitted successfully.",

            "request_id":
            join_request.id,

            "status":
            join_request.status.value,
        }



    # Admin pending list

    def get_pending(self):

        return (
            self.db.query(JoinRequest)
            .filter(
                JoinRequest.status ==
                JoinStatus.PENDING
            )
            .all()
        )



    # Admin approves and assigns unit

    def approve(
        self,
        request_id,
        unit_id,
    ):

        join_request = (
            self.db.query(JoinRequest)
            .filter(
                JoinRequest.id == request_id
            )
            .first()
        )


        if not join_request:
            raise HTTPException(
                status_code=404,
                detail="Join request not found.",
            )


        unit = self.unit_repo.get_by_id(
            unit_id
        )


        if not unit:
            raise HTTPException(
                status_code=404,
                detail="Unit not found.",
            )


        
        if (
            unit.property.organization_id
            != join_request.organization_id
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Unit does not belong to resident organization.",
            )


        resident = self.resident_repo.get_by_user_id(
            join_request.user_id
        )


        resident.unit_id = unit.id
        resident.status = ResidentStatus.ACTIVE

        join_request.assigned_unit_id = unit.id
        join_request.status = JoinStatus.APPROVED

        self.db.commit()


        return {

            "message":
            "Resident approved successfully.",

            "resident_id":
            resident.id,

            "unit_id":
            unit.id,

        }



    def reject(
        self,
        request_id,
    ):


        join_request = (
            self.db.query(JoinRequest)
            .filter(
                JoinRequest.id == request_id
            )
            .first()
        )


        if not join_request:

            raise HTTPException(
                status_code=404,
                detail="Join request not found.",
            )


        join_request.status = JoinStatus.REJECTED


        self.db.commit()


        return {

            "message":
            "Join request rejected."

        }