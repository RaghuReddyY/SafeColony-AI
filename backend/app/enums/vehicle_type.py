from enum import Enum


class VehicleType(str, Enum):
    CAR = "Car"
    BIKE = "Bike"
    SCOOTER = "Scooter"