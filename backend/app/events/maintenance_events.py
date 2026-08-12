from dataclasses import dataclass


@dataclass(frozen=True)
class MaintenancePaidEvent:
    bill_id: int
    organization_id: int
    resident_id: int
    amount: str
    payment_method: str
