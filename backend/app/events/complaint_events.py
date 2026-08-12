from dataclasses import dataclass


@dataclass(frozen=True)
class ComplaintResolvedEvent:
    complaint_id: int
    organization_id: int
    resident_id: int
