from enum import Enum


class ResidentType(str, Enum):
    OWNER = "OWNER"
    TENANT = "TENANT"
    FAMILY = "FAMILY"