from app.ai.insights import AIInsightsEngine
from app.security.permissions import Permissions
from app.auth.role_permissions import ROLE_PERMISSIONS


def _metrics():
    return {
        "active_security_alerts": 1,
        "high_priority_alerts": 0,
        "open_incidents": 2,
        "active_vacations": 1,
        "visitors_inside": 3,
        "visitors_pending": 4,
        "visitors_today": 6,
        "visitors_approved": 2,
        "visitor_vehicles_today": 2,
        "deliveries_pending": 1,
        "deliveries_today": 4,
        "emergency_alerts_today": 0,
        "incidents_today": 1,
        "incident_severity": {"MEDIUM": 2},
        "open_complaints": 3,
        "complaints_today": 1,
        "escalated_complaints": 1,
        "active_amenities": 4,
        "pending_amenity_bookings": 2,
        "amenity_bookings_today": 3,
        "resident_vehicles": 20,
        "unread_notifications": 5,
        "notifications_today": 7,
        "weekly_visitors": 18,
        "security_staff": 4,
        "active_residents": 100,
        "maintenance": {"outstanding": 25000.0, "unpaid_bills": 8},
        "personal": {},
    }


def test_ai_generates_dashboard_feature_cards_for_admin():
    engine = AIInsightsEngine(None)
    cards = engine._cards("ORGANIZATION_ADMIN", _metrics())
    keys = {card["key"] for card in cards}
    assert "security_summary" in keys
    assert "incident_summary" in keys
    assert "visitor_insights" in keys
    assert "parking_prediction" in keys
    assert "daily_digest" in keys
    assert "report_generator" in keys
    assert "security_copilot" in keys


def test_role_specific_ai_cards_are_present():
    engine = AIInsightsEngine(None)
    resident_keys = {c["key"] for c in engine._cards("RESIDENT", _metrics())}
    guard_keys = {c["key"] for c in engine._cards("SECURITY_GUARD", _metrics())}
    assert "resident_assistant" in resident_keys
    assert "guard_assistant" in guard_keys


def test_chat_and_ai_permissions_are_assigned():
    assert Permissions.CHAT_VIEW in ROLE_PERMISSIONS[next(r for r in ROLE_PERMISSIONS if r.value == "RESIDENT")]
    assert Permissions.CHAT_SEND in ROLE_PERMISSIONS[next(r for r in ROLE_PERMISSIONS if r.value == "SECURITY_GUARD")]
    assert Permissions.AI_ASSISTANT in ROLE_PERMISSIONS[next(r for r in ROLE_PERMISSIONS if r.value == "ORGANIZATION_ADMIN")]
