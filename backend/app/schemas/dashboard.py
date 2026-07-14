from pydantic import BaseModel


class ResidentDashboardResponse(BaseModel):

    resident_name: str

    unit_number: str

    vehicles: int

    pending_visitors: int

    approved_visitors: int

    inside_visitors: int

    notifications: int