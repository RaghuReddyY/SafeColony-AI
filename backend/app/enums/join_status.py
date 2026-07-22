from enum import Enum


class JoinStatus(str, Enum):

    PENDING = "PENDING"

    APPROVED = "APPROVED"

    REJECTED = "REJECTED"