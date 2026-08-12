from dataclasses import dataclass


@dataclass(frozen=True)
class IncidentCreatedEvent:
    incident_id: int
    organization_id: int
    created_by_user_id: int
    title: str
