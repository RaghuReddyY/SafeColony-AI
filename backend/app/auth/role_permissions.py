from app.enums import UserRole
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

        Permissions.MAINTENANCE_VIEW,
        Permissions.MAINTENANCE_MANAGE,

        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,
        Permissions.INCIDENT_MANAGE,
        Permissions.INCIDENT_EVIDENCE,
        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,

        Permissions.COMPLAINT_VIEW,
        Permissions.COMPLAINT_CREATE,
        Permissions.COMPLAINT_MANAGE,
        Permissions.COMPLAINT_ESCALATE,
        Permissions.AMENITY_VIEW,
        Permissions.AMENITY_MANAGE,
        Permissions.AMENITY_BOOK,
        Permissions.AMENITY_APPROVE,

        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_CREATE,
        Permissions.NOTIFICATION_UPDATE,

        Permissions.EMERGENCY_VIEW,
        Permissions.EMERGENCY_RESOLVE,
        Permissions.SECURITY_ALERT_RAISE,
        Permissions.SECURITY_ALERT_RAISE,

        Permissions.VACATION_VIEW,
        Permissions.VACATION_CREATE,

        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
        Permissions.BLOCK_ADMIN_VIEW,
        Permissions.BLOCK_ADMIN_MANAGE,
        Permissions.COMMUNITY_FINANCE_VIEW,
        Permissions.COMMUNITY_FINANCE_MANAGE,
        Permissions.COMMUNITY_FINANCE_PAYMENT,
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

        Permissions.MAINTENANCE_VIEW,

        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,
        Permissions.INCIDENT_MANAGE,
        Permissions.INCIDENT_EVIDENCE,
        Permissions.COMPLAINT_VIEW,
        Permissions.COMPLAINT_MANAGE,
        Permissions.COMPLAINT_ESCALATE,
        Permissions.AMENITY_VIEW,
        Permissions.AMENITY_MANAGE,
        Permissions.AMENITY_BOOK,
        Permissions.AMENITY_APPROVE,

        Permissions.NOTIFICATION_VIEW,

        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,
        Permissions.INCIDENT_MANAGE,
        Permissions.INCIDENT_EVIDENCE,

        Permissions.EMERGENCY_VIEW,
        Permissions.EMERGENCY_RESOLVE,

        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
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

        Permissions.EMERGENCY_VIEW,
        Permissions.EMERGENCY_RAISE,
        Permissions.EMERGENCY_RESOLVE,
        Permissions.SECURITY_ALERT_RAISE,

        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
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
        Permissions.GUARD_DELIVERY_CREATE,
        Permissions.GUARD_DELIVERY_RECEIVE,
        Permissions.GUARD_DELIVERY_VERIFY,

        Permissions.GUARD_VEHICLE_VIEW,
        Permissions.GUARD_VEHICLE_ENTRY,
        Permissions.GUARD_VEHICLE_EXIT,

        Permissions.GUARD_QR_SCAN,
        Permissions.GUARD_WALKIN_VISITOR,

        Permissions.GUARD_PROPERTY_VIEW,
        Permissions.GUARD_SECTION_VIEW,
        Permissions.GUARD_UNIT_VIEW,
        Permissions.GUARD_RESIDENT_VIEW,

        # Notifications
        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_UPDATE,

        Permissions.EMERGENCY_VIEW,
        Permissions.EMERGENCY_RAISE,
        Permissions.EMERGENCY_RESOLVE,
        Permissions.SECURITY_ALERT_RAISE,

        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,
        Permissions.INCIDENT_EVIDENCE,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
    },


    # ==========================================================
    # Block Admin
    # ==========================================================
    UserRole.BLOCK_ADMIN: {
        Permissions.BLOCK_ADMIN_VIEW,
        Permissions.SECTION_VIEW,
        Permissions.UNIT_VIEW,
        Permissions.UNIT_CREATE,
        Permissions.RESIDENT_VIEW,
        Permissions.RESIDENT_CREATE,
        Permissions.RESIDENT_UPDATE,
        Permissions.RESIDENT_APPROVE,
        Permissions.RESIDENT_REJECT,
        Permissions.MAINTENANCE_VIEW,
        Permissions.MAINTENANCE_MANAGE,
        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,
        Permissions.INCIDENT_MANAGE,
        Permissions.INCIDENT_EVIDENCE,
        Permissions.COMPLAINT_VIEW,
        Permissions.COMPLAINT_CREATE,
        Permissions.COMPLAINT_MANAGE,
        Permissions.COMPLAINT_ESCALATE,
        Permissions.AMENITY_VIEW,
        Permissions.AMENITY_MANAGE,
        Permissions.AMENITY_BOOK,
        Permissions.AMENITY_APPROVE,
        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_UPDATE,
        Permissions.EMERGENCY_VIEW,
        Permissions.EMERGENCY_RESOLVE,
        Permissions.SECURITY_ALERT_RAISE,
        Permissions.VACATION_VIEW,
        Permissions.VACATION_CREATE,
        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
    },

    # ==========================================================
    # Community Finance Collector
    # ==========================================================
    UserRole.COMMUNITY_FINANCE_ADMIN: {
        Permissions.COMMUNITY_FINANCE_VIEW,
        Permissions.COMMUNITY_FINANCE_MANAGE,
        Permissions.COMMUNITY_FINANCE_PAYMENT,
        # Finance admins manage organization-wide collections (festivals, CCTV,
        # events, etc.). They do not create or collect monthly maintenance.
        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_CREATE,
        Permissions.NOTIFICATION_UPDATE,
        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,
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
        Permissions.DELIVERY_CREATE,

        Permissions.MAINTENANCE_VIEW,
        Permissions.MAINTENANCE_PAYMENT,

        # Residents can view organization-wide community funds and expenses.
        # Collection management remains restricted to finance/organization admins.
        Permissions.COMMUNITY_FINANCE_VIEW,
        Permissions.COMMUNITY_FINANCE_PAYMENT,

        Permissions.VACATION_VIEW,
        Permissions.VACATION_CREATE,
        Permissions.VACATION_CANCEL,

        # Notifications
        Permissions.NOTIFICATION_VIEW,
        Permissions.NOTIFICATION_UPDATE,

        Permissions.EMERGENCY_RAISE,
        Permissions.SECURITY_ALERT_RAISE,

        Permissions.COMPLAINT_VIEW,
        Permissions.COMPLAINT_CREATE,

        # Incident management: residents can report incidents and
        # view incidents for their community. Management actions
        # remain restricted to administrators/security managers.
        Permissions.INCIDENT_VIEW,
        Permissions.INCIDENT_CREATE,

        Permissions.AMENITY_VIEW,
        Permissions.AMENITY_BOOK,

        Permissions.DASHBOARD_VIEW,
        Permissions.CHAT_VIEW,
        Permissions.CHAT_SEND,
        Permissions.AI_ASSISTANT,

        Permissions.JOIN_REQUEST_VIEW,
        Permissions.JOIN_REQUEST_APPROVE,
        Permissions.JOIN_REQUEST_REJECT,
    },
}