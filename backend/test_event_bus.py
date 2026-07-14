from app.core.event_bus import event_bus

from app.events.vacation_events import (
    VacationStartedEvent,
)

from app.handlers.resident_notification_handler import (
    ResidentNotificationHandler,
)

event_bus.subscribe(
    VacationStartedEvent,
    ResidentNotificationHandler(),
)

event = VacationStartedEvent(
    resident_id=2,
    start_date="2026-07-20",
    end_date="2026-07-30",
    allow_visitors=False,
    allow_deliveries=True,
)

event_bus.publish(event)