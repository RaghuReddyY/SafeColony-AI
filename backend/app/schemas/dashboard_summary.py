from pydantic import BaseModel


class DashboardSummaryResponse(BaseModel):

    resident_name: str

    unit_number: str

    visitor_count: int

    pending_visitors: int

    delivery_count: int

    pending_deliveries: int

    notification_count: int

    unread_notifications: int

    vacation_mode: bool

    security_score: int