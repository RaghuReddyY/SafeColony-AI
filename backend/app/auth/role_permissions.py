from app.models.user import UserRole
from app.security.permissions import Permissions

ROLE_PERMISSIONS = {

    # ==========================================================
    # System Admin
    # ==========================================================
    UserRole.SYSTEM_ADMIN: {
        value
        for name, value in Permissions.__dict__.items()
        if not name.startswith("_")
    },

    # ==========================================================
    # Organization Admin
    # ==========================================================
    UserRole.ORGANIZATION_ADMIN: {

        Permissions.ORGANIZATION_VIEW,
        Permissions.ORGANIZATION_CREATE,
        Permissions.ORGANIZATION_UPDATE,

        Permissions.PROPERTY_VIEW,
        Permissions.PROPERTY_CREATE,

        Permissions.SECTION_VIEW,
        Permissions.SECTION_CREATE,

        Permissions.UNIT_VIEW,
        Permissions.UNIT_CREATE,

        Permissions.RESIDENT_VIEW,
        Permissions.RESIDENT_CREATE,
        Permissions.RESIDENT_UPDATE,
        Permissions.RESIDENT_APPROVE,
        Permissions.RESIDENT_REJECT,

        Permissions.VISITOR_VIEW,
        Permissions.VISITOR_CREATE,
        Permissions.VISITOR_APPROVE,
        Permissions.VISITOR_REJECT,

        Permissions.VEHICLE_VIEW,
        Permissions.VEHICLE_CREATE,

        Permissions.DELIVERY_VIEW,
        Permissions.DELIVERY_CREATE,

        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_CREATE,

        Permissions.VACATION_VIEW,
        Permissions.VACATION_CREATE,

        Permissions.DASHBOARD_VIEW,
    },

    # ==========================================================
    # Property Manager
    # ==========================================================
    UserRole.PROPERTY_MANAGER: {

        Permissions.SECTION_VIEW,
        Permissions.SECTION_CREATE,

        Permissions.UNIT_VIEW,
        Permissions.UNIT_CREATE,

        Permissions.RESIDENT_VIEW,
        Permissions.RESIDENT_CREATE,
        Permissions.RESIDENT_UPDATE,

        Permissions.VISITOR_VIEW,

        Permissions.VEHICLE_VIEW,

        Permissions.DELIVERY_VIEW,

        Permissions.NOTIFICATION_VIEW,

        Permissions.DASHBOARD_VIEW,
    },

    # ==========================================================
    # Security Manager
    # ==========================================================
    UserRole.SECURITY_MANAGER: {

        Permissions.VISITOR_VIEW,
        Permissions.VISITOR_APPROVE,
        Permissions.VISITOR_REJECT,
        Permissions.VISITOR_CHECKIN,
        Permissions.VISITOR_CHECKOUT,
        Permissions.VISITOR_QR_SCAN,
        Permissions.VISITOR_QR_VALIDATE,
        Permissions.VISITOR_QR_EXIT,

        Permissions.VEHICLE_VIEW,

        Permissions.DELIVERY_VIEW,
        Permissions.DELIVERY_RECEIVE,
        Permissions.DELIVERY_VERIFY,

        Permissions.GUARD_DASHBOARD,
        Permissions.GUARD_VISITOR_VIEW,
        Permissions.GUARD_VISITOR_CHECKIN,
        Permissions.GUARD_VISITOR_CHECKOUT,
        Permissions.GUARD_DELIVERY_VIEW,
        Permissions.GUARD_DELIVERY_RECEIVE,
        Permissions.GUARD_DELIVERY_VERIFY,
        Permissions.GUARD_VEHICLE_VIEW,
        Permissions.GUARD_VEHICLE_ENTRY,
        Permissions.GUARD_VEHICLE_EXIT,
        Permissions.GUARD_QR_SCAN,

        Permissions.NOTIFICATION_VIEW,

        Permissions.DASHBOARD_VIEW,
    },

    # ==========================================================
    # Security Guard
    # ==========================================================
    UserRole.SECURITY_GUARD: {

        Permissions.GUARD_DASHBOARD,

        Permissions.GUARD_VISITOR_VIEW,
        Permissions.GUARD_VISITOR_CHECKIN,
        Permissions.GUARD_VISITOR_CHECKOUT,

        Permissions.GUARD_DELIVERY_VIEW,
        Permissions.GUARD_DELIVERY_RECEIVE,
        Permissions.GUARD_DELIVERY_VERIFY,

        Permissions.GUARD_VEHICLE_VIEW,
        Permissions.GUARD_VEHICLE_ENTRY,
        Permissions.GUARD_VEHICLE_EXIT,

        Permissions.GUARD_QR_SCAN,
    },

    # ==========================================================
    # Resident
    # ==========================================================
    UserRole.RESIDENT: {

        Permissions.RESIDENT_PROFILE_VIEW,
        Permissions.RESIDENT_PROFILE_UPDATE,
        Permissions.RESIDENT_DASHBOARD_VIEW,

        Permissions.VISITOR_CREATE,
        Permissions.VISITOR_VIEW,

        Permissions.VEHICLE_VIEW,
        Permissions.VEHICLE_CREATE,

        Permissions.DELIVERY_VIEW,

        Permissions.VACATION_VIEW,
        Permissions.VACATION_CREATE,
        Permissions.VACATION_CANCEL,

        Permissions.NOTIFICATION_VIEW,

        Permissions.DASHBOARD_VIEW,

        Permissions.JOIN_REQUEST_VIEW,
        Permissions.JOIN_REQUEST_APPROVE,
        Permissions.JOIN_REQUEST_REJECT,
    },
}



