from collections import defaultdict


class EventBus:

    def __init__(self):

        self._handlers = defaultdict(set)

    def subscribe(
        self,
        event_type,
        handler,
    ):

        self._handlers[event_type].add(handler)

    def publish(self, event):

        handlers = self._handlers.get(
            type(event),
            set(),
        )

        for handler in handlers:

            handler(event)


event_bus = EventBus()