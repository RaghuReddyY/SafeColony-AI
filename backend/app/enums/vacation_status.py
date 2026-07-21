from enum import Enum


class VacationStatus(str, Enum):
    """
    Lifecycle of a vacation request.

    SCHEDULED  -> Vacation is created but has not started yet.
    ACTIVE     -> Vacation is currently in progress.
    COMPLETED  -> Vacation has ended automatically.
    CANCELLED  -> Vacation was cancelled before completion.
    """

    SCHEDULED = "SCHEDULED"
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"