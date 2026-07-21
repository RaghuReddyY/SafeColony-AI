from enum import Enum

class DeliveryPriority(str, Enum):
    NORMAL = "NORMAL"
    URGENT = "URGENT"
    MEDICINE = "MEDICINE"
    PERISHABLE = "PERISHABLE"