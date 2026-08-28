from datetime import date, datetime

from pydantic import BaseModel


class RecentActivity(BaseModel):
    title: str
    message: str
    notification_type: str
    created_at: datetime
    is_read: bool
    count: int = 1


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
    pending_maintenance: float = 0
    latest_maintenance_status: str | None = None
    latest_maintenance_due_date: datetime | None = None
    latest_maintenance_period_month: date | None = None
    latest_maintenance_carry_forward: float = 0
    community_finance_pending: float = 0
    community_expense_total: float = 0
    recent_maintenance_payments: int = 0
    latest_maintenance_paid: float = 0
    community_finance_active: int = 0
    community_finance_contribution: float = 0
    vacation_mode: bool
    security_score: int
    weekly_visitors: list[int]
    recent_activity: list[RecentActivity]
    recommendation: str
    weather_temperature: float | None = None
    weather_city: str | None = None
    weather_description: str | None = None
    community_status: str
