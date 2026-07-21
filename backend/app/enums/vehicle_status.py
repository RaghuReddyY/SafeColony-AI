from enum import Enum


class VehicleStatus(str, Enum):
    OUTSIDE = "OUTSIDE"
    INSIDE = "INSIDE"