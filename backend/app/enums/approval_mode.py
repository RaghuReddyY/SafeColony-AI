from enum import Enum


class ApprovalMode(str, Enum):
    RESIDENT = "RESIDENT"
    GUARD = "GUARD"
    AUTO = "AUTO"