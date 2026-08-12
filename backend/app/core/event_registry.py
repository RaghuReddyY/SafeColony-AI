from app.core.event_bus import event_bus

from app.events.vacation_events import (
    VacationStartedEvent,
    VacationCancelledEvent,
    VacationCompletedEvent,
)

from app.handlers.resident_notification_handler import (
    ResidentNotificationHandler,
)


def register_event_handlers():

    handler = ResidentNotificationHandler()

    event_bus.subscribe(
        VacationStartedEvent,
        handler,
    )

    event_bus.subscribe(
        VacationCancelledEvent,
        handler,
    )

    event_bus.subscribe(
        VacationCompletedEvent,
        handler,
    )