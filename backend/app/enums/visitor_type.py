from enum import Enum


class VisitorType(str, Enum):
    GUEST = "Guest"
    DELIVERY = "Delivery"
    MAID = "Maid"
    DRIVER = "Driver"
    TAXI = "Taxi"
    RELATIVE = "Relative"
    OTHER = "Other"