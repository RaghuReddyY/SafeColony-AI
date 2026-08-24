from collections import Counter
from datetime import datetime, timedelta
from decimal import Decimal

from sqlalchemy import func

from app.models.amenity import Amenity, AmenityBooking
from app.models.complaint import Complaint
from app.models.delivery import Delivery
from app.models.incident import Incident
from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_expense import MaintenanceExpense
from app.models.maintenance_period import MaintenancePeriod
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.security_alert import SecurityAlert
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.visitor import Visitor
from app.models.vacation_mode import VacationMode
from app.models.marketplace import MarketplaceEvent, MarketplaceOrder
from app.models.super_app import ServiceRequest, CommunityParcel, RecurringOrder


class AIInsightsEngine:
    """Builds role-aware AI insights from the live SafeColony dashboard data."""

    def __init__(self, db):
        self.db = db

    def build(self, user: User) -> dict:
        metrics = self._metrics(user)
        role = user.role
        cards = self._cards(role, metrics)
        return {
            "role": role,
            "generated_at": datetime.utcnow(),
            "metrics": metrics,
            "insights": cards,
            "future_features": [
                {
                    "key": "ai_cctv_integration",
                    "title": "AI CCTV Integration",
                    "status": "ROADMAP",
                    "description": "Connect camera streams for real-time computer-vision analysis with explicit privacy controls.",
                },
                {
                    "key": "ai_face_recognition",
                    "title": "AI Face Recognition",
                    "status": "OPTIONAL_ROADMAP",
                    "description": "Optional face verification with explicit privacy and consent controls.",
                },
                {
                    "key": "ai_voice_assistant",
                    "title": "AI Voice Assistant",
                    "status": "ROADMAP",
                    "description": "Voice-based resident and guard workflows.",
                },
                {
                    "key": "community_marketplace_intelligence",
                    "title": "Community Marketplace Intelligence",
                    "status": "ACTIVE",
                    "description": "Surface open community days, orders, service requests, recurring orders and delivery-hub workload.",
                },
                {
                    "key": "ai_action_intents",
                    "title": "AI Action Intents",
                    "status": "ACTIVE",
                    "description": "AI can classify shopping, service, utility and issue requests into safe, confirmation-required actions.",
                },
            ],
        }

    def _org_filter(self, query, model, organization_id):
        return query.filter(model.organization_id == organization_id)

    def _metrics(self, user: User) -> dict:
        org_id = user.organization_id
        if not org_id:
            return {"organization_id": None}

        now = datetime.utcnow()
        today = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = today - timedelta(days=today.weekday())

        active_residents = self.db.query(func.count(Resident.id)).join(
            User, Resident.user_id == User.id
        ).filter(
            User.organization_id == org_id,
            Resident.is_active.is_(True),
        ).scalar() or 0
        security_staff = self.db.query(func.count(User.id)).filter(
            User.organization_id == org_id,
            User.role.in_(["SECURITY_GUARD", "SECURITY_MANAGER"]),
            User.is_active.is_(True),
        ).scalar() or 0

        visitors_pending = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.status == "PENDING",
        ).scalar() or 0
        visitors_approved = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.status == "APPROVED",
        ).scalar() or 0
        visitors_inside = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.status == "CHECKED_IN",
        ).scalar() or 0
        visitors_today = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.created_at >= today,
        ).scalar() or 0
        visitor_vehicles_today = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.created_at >= today,
            Visitor.vehicle_number.isnot(None),
        ).scalar() or 0

        deliveries_pending = self.db.query(func.count(Delivery.id)).join(
            Resident, Delivery.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
        ).scalar() or 0
        deliveries_today = self.db.query(func.count(Delivery.id)).join(
            Resident, Delivery.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Delivery.created_at >= today,
        ).scalar() or 0

        active_alerts = self.db.query(func.count(SecurityAlert.id)).filter(
            SecurityAlert.organization_id == org_id,
            SecurityAlert.is_resolved.is_(False),
        ).scalar() or 0
        critical_alerts = self.db.query(func.count(SecurityAlert.id)).filter(
            SecurityAlert.organization_id == org_id,
            SecurityAlert.is_resolved.is_(False),
            SecurityAlert.severity.in_(["HIGH", "CRITICAL"]),
        ).scalar() or 0
        emergency_alerts_today = self.db.query(func.count(SecurityAlert.id)).filter(
            SecurityAlert.organization_id == org_id,
            SecurityAlert.created_at >= today,
            SecurityAlert.alert_type.in_(["MEDICAL", "FIRE", "POLICE", "GENERAL"]),
        ).scalar() or 0

        open_incidents = self.db.query(func.count(Incident.id)).filter(
            Incident.organization_id == org_id,
            Incident.status.in_(["OPEN", "INVESTIGATING", "IN_PROGRESS"]),
        ).scalar() or 0
        incidents_today = self.db.query(func.count(Incident.id)).filter(
            Incident.organization_id == org_id,
            Incident.created_at >= today,
        ).scalar() or 0
        incident_severity_rows = self.db.query(
            Incident.severity, func.count(Incident.id)
        ).filter(
            Incident.organization_id == org_id,
            Incident.status.in_(["OPEN", "INVESTIGATING", "IN_PROGRESS"]),
        ).group_by(Incident.severity).all()
        incident_severity = {str(k): int(v) for k, v in incident_severity_rows}

        open_complaints = self.db.query(func.count(Complaint.id)).filter(
            Complaint.organization_id == org_id,
            Complaint.status.in_(["OPEN", "ASSIGNED", "IN_PROGRESS", "ESCALATED"]),
        ).scalar() or 0
        complaints_today = self.db.query(func.count(Complaint.id)).filter(
            Complaint.organization_id == org_id,
            Complaint.created_at >= today,
        ).scalar() or 0
        escalated_complaints = self.db.query(func.count(Complaint.id)).filter(
            Complaint.organization_id == org_id,
            Complaint.status == "ESCALATED",
        ).scalar() or 0

        active_amenities = self.db.query(func.count(Amenity.id)).filter(
            Amenity.organization_id == org_id,
            Amenity.is_active.is_(True),
        ).scalar() or 0
        pending_bookings = self.db.query(func.count(AmenityBooking.id)).join(
            Amenity, AmenityBooking.amenity_id == Amenity.id
        ).filter(
            Amenity.organization_id == org_id,
            AmenityBooking.status == "PENDING",
        ).scalar() or 0
        bookings_today = self.db.query(func.count(AmenityBooking.id)).join(
            Amenity, AmenityBooking.amenity_id == Amenity.id
        ).filter(
            Amenity.organization_id == org_id,
            AmenityBooking.start_at >= today,
            AmenityBooking.start_at < today + timedelta(days=1),
            AmenityBooking.status.in_(["PENDING", "APPROVED"]),
        ).scalar() or 0

        active_vacations = self.db.query(func.count(VacationMode.id)).join(
            Resident, VacationMode.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            VacationMode.status == "ACTIVE",
        ).scalar() or 0

        vehicles = self.db.query(func.count(Vehicle.id)).join(
            Resident, Vehicle.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
        ).scalar() or 0

        # Notifications are private to the logged-in user. Never aggregate
        # another resident's unread notifications into this user's AI context.
        unread_notifications = self.db.query(func.count(Notification.id)).filter(
            Notification.user_id == user.id,
            Notification.is_read.is_(False),
        ).scalar() or 0
        notifications_today = self.db.query(func.count(Notification.id)).filter(
            Notification.user_id == user.id,
            Notification.created_at >= today,
        ).scalar() or 0

        period = self.db.query(MaintenancePeriod).filter(
            MaintenancePeriod.organization_id == org_id
        ).order_by(MaintenancePeriod.month.desc()).first()
        maintenance = {
            "month": str(period.month) if period else None,
            "collected": 0.0,
            "expenses": 0.0,
            "unpaid_bills": 0,
            "outstanding": 0.0,
        }
        if period:
            collected = self.db.query(func.coalesce(func.sum(MaintenanceBill.amount_paid), 0)).filter(
                MaintenanceBill.period_id == period.id
            ).scalar() or Decimal("0")
            expenses = self.db.query(func.coalesce(func.sum(MaintenanceExpense.amount), 0)).filter(
                MaintenanceExpense.period_id == period.id
            ).scalar() or Decimal("0")
            unpaid = self.db.query(func.count(MaintenanceBill.id)).filter(
                MaintenanceBill.period_id == period.id,
                MaintenanceBill.status.in_(["UNPAID", "PARTIAL"]),
            ).scalar() or 0
            outstanding = self.db.query(
                func.coalesce(func.sum(MaintenanceBill.total_due - MaintenanceBill.amount_paid), 0)
            ).filter(
                MaintenanceBill.period_id == period.id,
                MaintenanceBill.status.in_(["UNPAID", "PARTIAL"]),
            ).scalar() or Decimal("0")
            maintenance.update({
                "collected": float(collected),
                "expenses": float(expenses),
                "unpaid_bills": int(unpaid),
                "outstanding": float(outstanding),
            })

        weekly_visitors = self.db.query(func.count(Visitor.id)).join(
            Resident, Visitor.resident_id == Resident.id
        ).join(User, Resident.user_id == User.id).filter(
            User.organization_id == org_id,
            Visitor.created_at >= week_start,
        ).scalar() or 0

        personal = {}
        if user.role == "RESIDENT":
            resident = self.db.query(Resident).filter(Resident.user_id == user.id).first()
            if resident:
                personal = {
                    "resident_id": resident.id,
                    "unit_number": resident.unit_number or "Not Assigned",
                    "my_pending_visitors": int(self.db.query(func.count(Visitor.id)).filter(
                        Visitor.resident_id == resident.id,
                        Visitor.status == "PENDING",
                    ).scalar() or 0),
                    "my_pending_deliveries": int(self.db.query(func.count(Delivery.id)).filter(
                        Delivery.resident_id == resident.id,
                        Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
                    ).scalar() or 0),
                    "my_unread_notifications": int(self.db.query(func.count(Notification.id)).filter(
                        Notification.user_id == user.id,
                        Notification.is_read.is_(False),
                    ).scalar() or 0),
                    "my_active_vacation": bool(self.db.query(VacationMode.id).filter(
                        VacationMode.resident_id == resident.id,
                        VacationMode.status == "ACTIVE",
                    ).first()),
                }
                latest_bill = self.db.query(MaintenanceBill).filter(
                    MaintenanceBill.resident_id == resident.id
                ).order_by(MaintenanceBill.due_date.desc()).first()
                if latest_bill:
                    personal.update({
                        "maintenance_status": latest_bill.status,
                        "maintenance_balance": float(
                            Decimal(str(latest_bill.total_due)) - Decimal(str(latest_bill.amount_paid))
                        ),
                        "maintenance_due_date": str(latest_bill.due_date),
                    })

        # Small, bounded detail lists make AI chat answers factual rather than
        # forcing Gemini to infer which incident/alert a count refers to.
        active_incident_rows = (
            self.db.query(Incident)
            .filter(
                Incident.organization_id == org_id,
                Incident.status.in_(["OPEN", "INVESTIGATING", "IN_PROGRESS"]),
            )
            .order_by(Incident.created_at.desc())
            .limit(20)
            .all()
        )
        active_alert_rows = (
            self.db.query(SecurityAlert)
            .filter(
                SecurityAlert.organization_id == org_id,
                SecurityAlert.is_resolved.is_(False),
            )
            .order_by(SecurityAlert.created_at.desc())
            .limit(20)
            .all()
        )
        my_notifications = (
            self.db.query(Notification)
            .filter(Notification.user_id == user.id)
            .order_by(Notification.created_at.desc())
            .limit(20)
            .all()
        )

        incident_details = [
            {
                "id": i.id,
                "title": i.title,
                "severity": i.severity,
                "status": i.status,
                "type": i.incident_type,
                "location": i.location,
                "created_at": i.created_at.isoformat() if i.created_at else None,
            }
            for i in active_incident_rows
        ]
        alert_details = [
            {
                "id": a.id,
                "type": a.alert_type,
                "severity": a.severity,
                "created_at": a.created_at.isoformat() if a.created_at else None,
            }
            for a in active_alert_rows
        ]
        notification_details = [
            {
                "id": n.id,
                "title": n.title,
                "type": n.notification_type,
                "is_read": n.is_read,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in my_notifications
        ]

        marketplace_open_events = self.db.query(func.count(MarketplaceEvent.id)).filter(
            MarketplaceEvent.organization_id == org_id, MarketplaceEvent.status == "OPEN"
        ).scalar() or 0
        marketplace_orders_today = self.db.query(func.count(MarketplaceOrder.id)).filter(
            MarketplaceOrder.organization_id == org_id, MarketplaceOrder.created_at >= today
        ).scalar() or 0
        service_requests_open = self.db.query(func.count(ServiceRequest.id)).filter(
            ServiceRequest.organization_id == org_id,
            ServiceRequest.status.in_(["REQUESTED","ASSIGNED","QUOTED","APPROVED","IN_PROGRESS"])
        ).scalar() or 0
        parcels_at_hub = self.db.query(func.count(CommunityParcel.id)).filter(
            CommunityParcel.organization_id == org_id, CommunityParcel.status == "AT_HUB"
        ).scalar() or 0
        recurring_orders = self.db.query(func.count(RecurringOrder.id)).filter(
            RecurringOrder.organization_id == org_id, RecurringOrder.active.is_(True)
        ).scalar() or 0

        return {
            "organization_id": org_id,
            "marketplace_open_events": int(marketplace_open_events),
            "marketplace_orders_today": int(marketplace_orders_today),
            "service_requests_open": int(service_requests_open),
            "parcels_at_hub": int(parcels_at_hub),
            "active_recurring_orders": int(recurring_orders),
            "active_residents": int(active_residents),
            "security_staff": int(security_staff),
            "visitors_pending": int(visitors_pending),
            "visitors_approved": int(visitors_approved),
            "visitors_inside": int(visitors_inside),
            "visitors_today": int(visitors_today),
            "visitor_vehicles_today": int(visitor_vehicles_today),
            "deliveries_pending": int(deliveries_pending),
            "deliveries_today": int(deliveries_today),
            "active_security_alerts": int(active_alerts),
            "high_priority_alerts": int(critical_alerts),
            "emergency_alerts_today": int(emergency_alerts_today),
            "open_incidents": int(open_incidents),
            "incidents_today": int(incidents_today),
            "incident_severity": incident_severity,
            "open_complaints": int(open_complaints),
            "complaints_today": int(complaints_today),
            "escalated_complaints": int(escalated_complaints),
            "active_amenities": int(active_amenities),
            "pending_amenity_bookings": int(pending_bookings),
            "amenity_bookings_today": int(bookings_today),
            "active_vacations": int(active_vacations),
            "resident_vehicles": int(vehicles),
            "unread_notifications": int(unread_notifications),
            "notifications_today": int(notifications_today),
            "weekly_visitors": int(weekly_visitors),
            "maintenance": maintenance,
            "personal": personal,
            "current_user_unread_notifications": int(unread_notifications),
            "current_user_notifications": notification_details,
            "active_incident_details": incident_details,
            "active_security_alert_details": alert_details,
        }

    @staticmethod
    def _card(key, title, category, summary, details, action=None, priority="NORMAL"):
        return {
            "key": key,
            "title": title,
            "category": category,
            "summary": summary,
            "details": details,
            "action": action,
            "priority": priority,
        }

    def _cards(self, role: str, m: dict) -> list[dict]:
        security_score = max(
            0,
            min(
                100,
                100
                - m["active_security_alerts"] * 12
                - m["open_incidents"] * 8
                - m["visitors_pending"] * 2
                - m["high_priority_alerts"] * 8,
            ),
        )
        security_status = "SAFE" if security_score >= 85 else "ATTENTION" if security_score >= 65 else "CRITICAL"

        risk = "LOW"
        if m["high_priority_alerts"] > 0 or m["open_incidents"] >= 3:
            risk = "HIGH"
        elif m["active_security_alerts"] > 0 or m["visitors_pending"] >= 5:
            risk = "MEDIUM"

        parking_demand = m["resident_vehicles"] + m["visitor_vehicles_today"]
        parking_level = "LOW"
        if parking_demand >= max(30, m["active_residents"]):
            parking_level = "HIGH"
        elif parking_demand >= max(10, m["active_residents"] // 2):
            parking_level = "MEDIUM"

        cards = [
            self._card(
                "super_app_operations",
                "AI Super-App Operations",
                "MARKETPLACE",
                f"{m.get('marketplace_open_events', 0)} community days are open, {m.get('marketplace_orders_today', 0)} marketplace orders were placed today, and {m.get('service_requests_open', 0)} service requests are active.",
                [
                    f"Delivery hub parcels waiting: {m.get('parcels_at_hub', 0)}.",
                    f"Active recurring orders: {m.get('active_recurring_orders', 0)}.",
                    "Use aggregated community ordering to reduce vendor trips and improve resident convenience.",
                ],
                "Review SafeColony Hub operations.",
            ),
            self._card(
                "security_summary",
                "AI Security Summary",
                "SECURITY",
                f"Community security is {security_status} with a calculated risk score of {security_score}/100.",
                [
                    f"{m['active_security_alerts']} unresolved security alerts ({m['high_priority_alerts']} high/critical).",
                    f"{m['open_incidents']} open incidents and {m['active_vacations']} homes in Vacation Mode.",
                    f"{m['visitors_inside']} visitors are currently inside; {m['visitors_pending']} are pending.",
                ],
                "Review unresolved security events first." if security_status != "SAFE" else "Continue normal security checks.",
                "HIGH" if security_status == "CRITICAL" else "NORMAL",
            ),
            self._card(
                "incident_summary",
                "AI Incident Summary",
                "INCIDENT",
                f"{m['open_incidents']} incidents currently require attention; {m['incidents_today']} were created today.",
                [f"Severity mix: {m['incident_severity'] or 'none open'}.", "Prioritize high/critical incidents and record investigation evidence."],
                "Open Incident Management",
                "HIGH" if m["open_incidents"] else "NORMAL",
            ),
            self._card(
                "visitor_insights",
                "AI Visitor Insights",
                "VISITOR",
                f"{m['visitors_today']} visitors were registered today and {m['visitors_inside']} are currently inside.",
                [
                    f"Pending approvals: {m['visitors_pending']}; approved and awaiting entry: {m['visitors_approved']}.",
                    f"Weekly visitor volume: {m['weekly_visitors']}.",
                    "Review repeated or unexpected visitor activity before entry.",
                ],
                "Review pending visitors",
            ),
            self._card(
                "visitor_risk_prediction",
                "AI Visitor Risk Prediction",
                "SECURITY",
                f"Current visitor risk is {risk} based on unresolved alerts, incidents and pending traffic.",
                [
                    "High risk is triggered by high/critical alerts or multiple open incidents.",
                    "Medium risk reflects elevated pending visitor traffic or unresolved alerts.",
                    "This is a decision-support score, not an automated rejection decision.",
                ],
                "Verify identity and authorization for higher-risk visits.",
                "HIGH" if risk == "HIGH" else "NORMAL",
            ),
            self._card(
                "parking_prediction",
                "AI Parking Prediction",
                "PARKING",
                f"Estimated current parking demand is {parking_level} ({parking_demand} resident/visitor vehicles represented in current data).",
                [
                    f"Resident vehicles registered: {m['resident_vehicles']}.",
                    f"Visitor vehicles registered today: {m['visitor_vehicles_today']}.",
                    "Use this as a planning signal until live parking occupancy sensors are integrated.",
                ],
                "Review parking/vehicle activity",
            ),
            self._card(
                "suspicious_activity",
                "AI Suspicious Activity Detection",
                "SECURITY",
                f"The current rules identify {m['active_security_alerts']} unresolved alerts and {m['open_incidents']} open incidents for review.",
                [
                    "Signals include high-severity alerts, open incidents and elevated visitor traffic.",
                    "No automatic enforcement is performed by this module.",
                ],
                "Review alerts and incidents",
                "HIGH" if m["high_priority_alerts"] else "NORMAL",
            ),
            self._card(
                "smart_notifications",
                "AI Smart Notifications",
                "NOTIFICATIONS",
                f"There are {m['unread_notifications']} unread community notifications and {m['notifications_today']} notifications today.",
                [
                    f"Emergency alerts today: {m['emergency_alerts_today']}.",
                    "Prioritize emergency, security and incident notifications before routine updates.",
                ],
                "Review notification inbox",
            ),
            self._card(
                "community_analytics",
                "AI Community Analytics",
                "COMMUNITY",
                f"The community has {m['active_residents']} active residents and {m['security_staff']} active security staff.",
                [
                    f"Visitors today: {m['visitors_today']}; deliveries today: {m['deliveries_today']}.",
                    f"Open complaints: {m['open_complaints']}; escalated: {m['escalated_complaints']}.",
                    f"Amenity bookings today: {m['amenity_bookings_today']}.",
                ],
                "Use the dashboard modules to investigate trends.",
            ),
            self._card(
                "daily_digest",
                "AI Daily Digest",
                "DIGEST",
                f"Today: {m['visitors_today']} visitors, {m['deliveries_today']} deliveries, {m['incidents_today']} incidents and {m['complaints_today']} complaints.",
                [
                    f"Emergency alerts: {m['emergency_alerts_today']}; unread notifications: {m['unread_notifications']}.",
                    f"Open incidents: {m['open_incidents']}; open complaints: {m['open_complaints']}.",
                ],
                "Start with unresolved high-priority items.",
            ),
            self._card(
                "reports",
                "AI Reports",
                "REPORT",
                "A live operational report is available from the current community data.",
                [
                    f"Security score: {security_score}/100 ({security_status}).",
                    f"Maintenance outstanding: ₹{m['maintenance']['outstanding']:.2f} across {m['maintenance']['unpaid_bills']} unpaid/partial bills.",
                    f"Amenity inventory: {m['active_amenities']} active; {m['pending_amenity_bookings']} pending bookings.",
                ],
                "Generate/export a detailed report in a future reporting module.",
            ),
            self._card(
                "incident_investigation",
                "AI Incident Investigation",
                "INCIDENT",
                "AI highlights what investigators should verify next without fabricating evidence.",
                [
                    "Check incident severity, location, assigned investigator, evidence and investigation notes.",
                    "Correlate incidents with security alerts and visitor activity from the same period.",
                ],
                "Open the incident and add evidence/notes.",
            ),
            self._card(
                "report_generator",
                "AI Report Generator",
                "REPORT",
                "The current dashboard data can be summarized into an administrator, security or resident report.",
                [
                    "Administrator reports emphasize community operations, finance, complaints and incidents.",
                    "Security reports emphasize alerts, visitors, incidents, vacations and vehicles.",
                    "Resident reports emphasize personal visitors, deliveries, maintenance, vacation and notifications.",
                ],
                "Ask SafeColony AI to create a report for a specific date range.",
            ),
            self._card(
                "security_copilot",
                "AI Security Copilot",
                "COPILOT",
                "Ask the AI chat for next-step guidance using the same live dashboard context shown here.",
                [
                    "The assistant is role-aware and must not expose another user's private data.",
                    "Use the chat for operational questions, incident triage and report drafting.",
                ],
                "Open AI Assistant",
            ),
        ]

        # Resident view: keep community analytics high-level and add personal guidance.
        if role == "RESIDENT":
            personal = m.get("personal", {})
            cards.insert(1, self._card(
                "resident_assistant",
                "AI Resident Assistant",
                "RESIDENT",
                f"Your unit is {personal.get('unit_number', 'not assigned')} with {personal.get('my_pending_visitors', 0)} pending visitors and {personal.get('my_pending_deliveries', 0)} pending deliveries.",
                [
                    f"Maintenance: {personal.get('maintenance_status', 'No latest bill found')} with balance ₹{personal.get('maintenance_balance', 0):.2f}.",
                    f"Vacation Mode: {'ACTIVE' if personal.get('my_active_vacation') else 'INACTIVE'}.",
                    f"Unread notifications: {personal.get('my_unread_notifications', 0)}.",
                ],
                "Ask AI about your visitors, maintenance, vacation or notifications.",
            ))
        elif role in {"SECURITY_GUARD", "SECURITY_MANAGER"}:
            cards.insert(1, self._card(
                "guard_assistant",
                "AI Guard Assistant",
                "GUARD",
                f"Gate workload: {m['visitors_pending']} pending visitors, {m['visitors_approved']} approved visitors and {m['deliveries_pending']} pending deliveries.",
                [
                    f"Visitors inside: {m['visitors_inside']}; visitor vehicles today: {m['visitor_vehicles_today']}.",
                    f"Unresolved security alerts: {m['active_security_alerts']}.",
                    "Verify QR/identity, resident authorization and entry status before allowing access.",
                ],
                "Ask AI for gate/security next steps.",
                "HIGH" if m["high_priority_alerts"] else "NORMAL",
            ))

        return cards
