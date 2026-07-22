from enum import Enum


class UnitType(str, Enum):
    APARTMENT = "APARTMENT"
    VILLA = "VILLA"
    SHOP = "SHOP"
    OFFICE = "OFFICE"