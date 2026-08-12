from datetime import date, timedelta
from decimal import Decimal
from types import SimpleNamespace

from app.schemas.amenity import AmenityBookingCreate
from app.schemas.complaint import ComplaintCreate
from app.schemas.incident import IncidentCreate
from app.schemas.security_alert import EmergencySOSCreate, SecurityAlertCreate
from app.services.maintenance_service import MaintenanceService


class FakeRepo:
    def __init__(self):
        self.db = None


def test_emergency_sos_schema_defaults():
    data = EmergencySOSCreate(emergency_type="FIRE")
    assert data.emergency_type == "FIRE"
    assert data.severity == "CRITICAL"


def test_security_alert_schema():
    data = SecurityAlertCreate(alert_type="TAILGATING", severity="HIGH")
    assert data.alert_type == "TAILGATING"


def test_incident_schema():
    data = IncidentCreate(
        title="Gate incident",
        description="Unknown vehicle at gate",
        incident_type="SECURITY",
    )
    assert data.incident_type == "SECURITY"


def test_complaint_schema():
    data = ComplaintCreate(
        title="Water leakage",
        description="Leak in common area",
        category="PLUMBING",
    )
    assert data.priority == "MEDIUM"


def test_amenity_booking_rejects_invalid_time_at_service_boundary():
    data = AmenityBookingCreate(
        amenity_id=1,
        start_at=date.today().isoformat() + "T10:00:00",
        end_at=date.today().isoformat() + "T11:00:00",
        purpose="Gym",
    )
    assert data.end_at > data.start_at


def test_late_fee_flat_policy():
    service = MaintenanceService(FakeRepo())
    bill = SimpleNamespace(
        status="UNPAID",
        due_date=date.today() - timedelta(days=5),
        amount=Decimal("1000.00"),
        carried_forward=Decimal("0.00"),
        late_fee=Decimal("0.00"),
        total_due=Decimal("1000.00"),
        amount_paid=Decimal("0.00"),
        paid_at=None,
    )
    organization = SimpleNamespace(
        late_fee_type="FLAT",
        late_fee_value=Decimal("100.00"),
        late_fee_grace_days=0,
    )
    service._apply_late_fee(bill, organization)
    assert bill.late_fee == Decimal("100.00")
    assert bill.total_due == Decimal("1100.00")


def test_late_fee_grace_period():
    service = MaintenanceService(FakeRepo())
    bill = SimpleNamespace(
        status="UNPAID",
        due_date=date.today() - timedelta(days=2),
        amount=Decimal("1000.00"),
        carried_forward=Decimal("0.00"),
        late_fee=Decimal("0.00"),
        total_due=Decimal("1000.00"),
        amount_paid=Decimal("0.00"),
        paid_at=None,
    )
    organization = SimpleNamespace(
        late_fee_type="PER_DAY",
        late_fee_value=Decimal("10.00"),
        late_fee_grace_days=3,
    )
    service._apply_late_fee(bill, organization)
    assert bill.late_fee == Decimal("0.00")
