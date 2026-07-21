from enum import Enum

class DeliveryStatus(str, Enum):
    ARRIVED = "ARRIVED"
    NOTIFIED = "NOTIFIED"
    COLLECTED = "COLLECTED"
    REJECTED = "REJECTED"
    RETURNED = "RETURNED"