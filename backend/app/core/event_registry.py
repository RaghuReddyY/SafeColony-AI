from app.core.event_bus import event_bus

from app.events.vacation_events import (
    VacationStartedEvent,
)

from app.handlers.resident_notification_handler import (
    ResidentNotificationHandler,
)


def register_event_handlers():

    event_bus.subscribe(
        VacationStartedEvent,
        ResidentNotificationHandler(),
    )