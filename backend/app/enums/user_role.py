from enum import Enum


class UserRole(str, Enum):
    SUPER_ADMIN = "super_admin"
    PROPERTY_ADMIN = "property_admin"
    SECURITY = "security"
    RESIDENT = "resident"
    MAINTENANCE = "maintenance"