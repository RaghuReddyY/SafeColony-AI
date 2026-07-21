from datetime import date

from app.events.base_event import BaseEvent


class VacationStartedEvent(BaseEvent):
    """
    Published when a vacation becomes ACTIVE.
    """

    def __init__(
        self,
        resident_id: int,
        resident_name: str,
        start_date: date,
        end_date: date,
        visitor_policy: str,
        delivery_policy: str,
    ):
        super().__init__()

        self.resident_id = resident_id
        self.resident_name = resident_name
        self.start_date = start_date
        self.end_date = end_date

        self.visitor_policy = visitor_policy
        self.delivery_policy = delivery_policy


class VacationCancelledEvent(BaseEvent):
    """
    Published when a vacation is cancelled.
    """

    def __init__(
        self,
        resident_id: int,
        resident_name: str,
    ):
        super().__init__()

        self.resident_id = resident_id
        self.resident_name = resident_name