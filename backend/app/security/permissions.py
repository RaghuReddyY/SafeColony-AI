class Permissions:

    # ==========================================================
    # Organization
    # ==========================================================

    ORGANIZATION_VIEW = "organization:view"
    ORGANIZATION_CREATE = "organization:create"
    ORGANIZATION_UPDATE = "organization:update"
    ORGANIZATION_DELETE = "organization:delete"

    # ==========================================================
    # Property
    # ==========================================================

    PROPERTY_VIEW = "property:view"
    PROPERTY_CREATE = "property:create"
    PROPERTY_UPDATE = "property:update"
    PROPERTY_DELETE = "property:delete"

    # ==========================================================
    # Section
    # ==========================================================

    SECTION_VIEW = "section:view"
    SECTION_CREATE = "section:create"
    SECTION_UPDATE = "section:update"
    SECTION_DELETE = "section:delete"

    # ==========================================================
    # Unit
    # ==========================================================

    UNIT_VIEW = "unit:view"
    UNIT_CREATE = "unit:create"
    UNIT_UPDATE = "unit:update"
    UNIT_DELETE = "unit:delete"

    # ==========================================================
    # Resident
    # ==========================================================

    RESIDENT_VIEW = "resident:view"
    RESIDENT_CREATE = "resident:create"
    RESIDENT_UPDATE = "resident:update"
    RESIDENT_DELETE = "resident:delete"

    RESIDENT_APPROVE = "resident:approve"
    RESIDENT_REJECT = "resident:reject"

    RESIDENT_PROFILE_VIEW = "resident:profile:view"
    RESIDENT_PROFILE_UPDATE = "resident:profile:update"
    RESIDENT_DASHBOARD_VIEW = "resident:dashboard:view"
    # ==========================================================
    # Visitor
    # ==========================================================

    VISITOR_VIEW = "visitor:view"
    VISITOR_CREATE = "visitor:create"
    VISITOR_APPROVE = "visitor:approve"
    VISITOR_REJECT = "visitor:reject"

    VISITOR_CHECKIN = "visitor:checkin"
    VISITOR_CHECKOUT = "visitor:checkout"

    VISITOR_QR_VALIDATE = "visitor:qr:validate"
    VISITOR_QR_SCAN = "visitor:qr:scan"
    VISITOR_QR_EXIT = "visitor:qr:exit"

    # ==========================================================
    # Vehicle
    # ==========================================================

    VEHICLE_VIEW = "vehicle:view"
    VEHICLE_CREATE = "vehicle:create"

    # ==========================================================
    # Delivery
    # ==========================================================

    DELIVERY_VIEW = "delivery:view"
    DELIVERY_CREATE = "delivery:create"
    DELIVERY_RECEIVE = "delivery:receive"
    DELIVERY_VERIFY = "delivery:verify"

    # ==========================================================
    # Notification
    # ==========================================================

    NOTIFICATION_VIEW = "notification:view"
    NOTIFICATION_CREATE = "notification:create"
    NOTIFICATION_UPDATE = "notification:update"

    # ==========================================================
    # Vacation
    # ==========================================================

    VACATION_VIEW = "vacation:view"
    VACATION_CREATE = "vacation:create"
    VACATION_CANCEL = "vacation:cancel"

    # ==========================================================
    # Guard
    # ==========================================================

    GUARD_DASHBOARD = "guard:dashboard"

    GUARD_VISITOR_VIEW = "guard:visitor:view"

    GUARD_VISITOR_CHECKIN = "guard:visitor:checkin"
    GUARD_VISITOR_CHECKOUT = "guard:visitor:checkout"

    GUARD_DELIVERY_VIEW = "guard:delivery:view"
    GUARD_DELIVERY_RECEIVE = "guard:delivery:receive"
    GUARD_DELIVERY_VERIFY = "guard:delivery:verify"

    GUARD_VEHICLE_VIEW = "guard:vehicle:view"
    GUARD_VEHICLE_ENTRY = "guard:vehicle:entry"
    GUARD_VEHICLE_EXIT = "guard:vehicle:exit"

    GUARD_QR_SCAN = "guard:qr:scan"

    # ==========================================================
    # Dashboard
    # ==========================================================

    DASHBOARD_VIEW = "dashboard:view"

    JOIN_REQUEST_VIEW = "join_request:view"
    JOIN_REQUEST_APPROVE = "join_request:approve"
    JOIN_REQUEST_REJECT = "join_request:reject"