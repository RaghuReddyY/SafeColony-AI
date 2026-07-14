from enum import Enum


class UnitStatus(str, Enum):
    VACANT = "VACANT"
    OCCUPIED = "OCCUPIED"