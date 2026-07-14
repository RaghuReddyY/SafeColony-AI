from pydantic import BaseModel

from app.schemas.security_alert import (
    SecurityAlertResponse,
)


class SecurityDashboardResponse(BaseModel):

    active_alerts: int

    vacation_homes: int

    visitors_inside: int

    pending_visitors: int

    vehicles_inside: int

    unread_notifications: int

    latest_alerts: list[SecurityAlertResponse]

    community_status: str

    risk_score: int

    ai_summary: str

    recommendation: str