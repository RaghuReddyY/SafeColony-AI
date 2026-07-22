from pydantic import BaseModel

from app.enums import ResidentType


class JoinOrganizationRequest(BaseModel):

    organization_id: int

    resident_type: ResidentType = ResidentType.OWNER



class ApproveJoinRequest(BaseModel):

    unit_id: int