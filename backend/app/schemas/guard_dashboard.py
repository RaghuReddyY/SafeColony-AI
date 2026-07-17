from datetime import datetime
from typing import Optional

from pydantic import BaseModel
from app.schemas.recent_activity import RecentActivityResponse

class ExpectedVisitorResponse(BaseModel):

    id: int
    visitor_name: str
    resident_id: int

    visitor_type: str
    phone: str

    purpose: Optional[str] = None
    vehicle_number: Optional[str] = None

    expected_time: Optional[datetime] = None

    status: str

    class Config:
        from_attributes = True


class GuardDashboardSummary(BaseModel):

    expected_visitors: int

    walk_in_requests: int

    deliveries: int

    vacant_houses: int

    checked_in_today: int


class GuardDashboardResponse(BaseModel):

    summary: GuardDashboardSummary

    expected_visitors: list[ExpectedVisitorResponse]

    recent_activities: list[RecentActivityResponse]

    ai_message: str