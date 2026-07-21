from enum import Enum


class VehicleType(str, Enum):
    CAR = "Car"
    BIKE = "Bike"
    SCOOTER = "Scooter"
    BICYCLE = "Bicycle"
    EV = "EV"
    OTHER = "Other"