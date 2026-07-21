from enum import Enum

class DeliveryCategory(str, Enum):
    PACKAGE = "PACKAGE"
    FOOD = "FOOD"
    GROCERY = "GROCERY"
    MEDICINE = "MEDICINE"
    DOCUMENT = "DOCUMENT"
    OTHER = "OTHER"