from enum import Enum


class DeliveryPolicy(str, Enum):
    """
    Delivery handling policy during vacation mode.
    """

    ALLOW = "ALLOW"

    KEEP_AT_GATE = "KEEP_AT_GATE"

    REJECT = "REJECT"