from datetime import datetime

from pydantic import BaseModel


class RecentActivity(BaseModel):
    title: str
    message: str
    notification_type: str
    created_at: datetime
    is_read: bool


class DashboardSummaryResponse(BaseModel):
    resident_name: str
    unit_number: str
    section_name: str | None = None
    organization_name: str | None = None
    organization_code: str | None = None
    visitor_count: int
    pending_visitors: int
    delivery_count: int
    pending_deliveries: int
    notification_count: int
    unread_notifications: int
    vacation_mode: bool
    security_score: int
    weekly_visitors: list[int]
    recent_activity: list[RecentActivity]
    recommendation: str
    weather_temperature: float | None = None
    weather_city: str | None = None
    weather_description: str | None = None
    community_status: str
