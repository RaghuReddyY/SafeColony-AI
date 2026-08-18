from datetime import datetime, timezone


class BaseEvent:

    def __init__(self):
        self.timestamp = datetime.now(timezone.utc)
        