from datetime import date

from app.core.event_bus import event_bus
from app.core.event_registry import register_event_handlers
from app.events.vacation_events import (
    VacationStartedEvent,
    VacationCancelledEvent,
    VacationCompletedEvent,
)


def test_vacation_started_event_creation():
    event = VacationStartedEvent(
        user_id=1,
        resident_id=101,
        resident_name="Test Resident",
        start_date=date(2026, 8, 18),
        end_date=date(2026, 8, 25),
        visitor_policy="BLOCK",
        delivery_policy="BLOCK",
    )

    assert event.user_id == 1
    assert event.resident_id == 101
    assert event.resident_name == "Test Resident"
    assert event.start_date == date(2026, 8, 18)
    assert event.end_date == date(2026, 8, 25)
    assert event.visitor_policy == "BLOCK"
    assert event.delivery_policy == "BLOCK"


def test_event_bus_registers_vacation_handlers():
    register_event_handlers()

    assert VacationStartedEvent in event_bus._handlers
    assert VacationCancelledEvent in event_bus._handlers
    assert VacationCompletedEvent in event_bus._handlers

    assert len(event_bus._handlers[VacationStartedEvent]) > 0
    assert len(event_bus._handlers[VacationCancelledEvent]) > 0
    assert len(event_bus._handlers[VacationCompletedEvent]) > 0