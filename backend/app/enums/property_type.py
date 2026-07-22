from enum import Enum


class PropertyType(str, Enum):
    APARTMENT = "APARTMENT"
    VILLA = "VILLA"
    GATED_COMMUNITY = "GATED_COMMUNITY"
    COMMERCIAL = "COMMERCIAL"
    MIXED_USE = "MIXED_USE"