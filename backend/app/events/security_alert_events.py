from dataclasses import dataclass


@dataclass(frozen=True)
class SecurityAlertRaisedEvent:
    alert_id: int
    organization_id: int
    alert_type: str
    severity: str
    raised_by_user_id: int
