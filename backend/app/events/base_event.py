from datetime import datetime


class BaseEvent:

    def __init__(self):

        self.timestamp = datetime.utcnow()