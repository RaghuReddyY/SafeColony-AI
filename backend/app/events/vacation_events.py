from app.events.base_event import BaseEvent


class VacationStartedEvent(BaseEvent):

    def __init__(
        self,
        resident_id: int,
        resident_name: str,
        start_date,
        end_date,
        allow_visitors: bool,
        allow_deliveries: bool,
    ):

        super().__init__()

        self.resident_id = resident_id
        self.resident_name = resident_name
        self.start_date = start_date
        self.end_date = end_date
        self.allow_visitors = allow_visitors
        self.allow_deliveries = allow_deliveries


class VacationCancelledEvent(BaseEvent):

    def __init__(
        self,
        resident_id: int,
        resident_name: str,
    ):

        super().__init__()

        self.resident_id = resident_id
        self.resident_name = resident_name