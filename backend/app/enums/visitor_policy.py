from enum import Enum


class VisitorPolicy(str, Enum):
    """
    Visitor access policy during vacation mode.
    """

    ALLOW_ALL = "ALLOW_ALL"

    ALLOW_PRE_APPROVED = "ALLOW_PRE_APPROVED"

    REJECT_ALL = "REJECT_ALL"