import json
from datetime import datetime
from zoneinfo import ZoneInfo
import urllib.error
import urllib.request
from decimal import Decimal

from sqlalchemy import func

from app.config import settings
from app.ai.insights import AIInsightsEngine
from app.core.exceptions import BadRequestException
from app.core.logger import logger
from app.models.delivery import Delivery
from app.models.maintenance_bill import MaintenanceBill
from app.models.maintenance_period import MaintenancePeriod
from app.models.maintenance_expense import MaintenanceExpense
from app.models.resident import Resident
from app.models.user import User
from app.models.visitor import Visitor
from app.models.complaint import Complaint
from app.models.vacation_mode import VacationMode
from app.repositories.resident_repository import ResidentRepository


class AIAssistant:
    """Role-aware SafeColony assistant backed by Gemini."""

    def __init__(self, db):
        self.db = db

    def _local_intent_response(self, user: User, text: str) -> str | None:
        """Answer common SafeColony intents directly from authorized DB data.

        This avoids making a network round-trip to Gemini for deterministic
        application data and means temporary Gemini failures do not turn
        simple dashboard questions into a generic 'server unavailable' error.
        """
        q = text.lower().strip()
        resident = None
        if user.role == "RESIDENT":
            resident = ResidentRepository(self.db).get_by_user_id(user.id)

        if "pending maintenance" in q or "maintenance status" in q or "maintenance balance" in q:
            if not resident:
                return "Maintenance details are available only for a resident account."
            bills = (self.db.query(MaintenanceBill)
                     .filter(MaintenanceBill.resident_id == resident.id)
                     .order_by(MaintenanceBill.due_date.desc()).limit(10).all())
            pending = []
            for bill in bills:
                balance = Decimal(str(bill.total_due or 0)) - Decimal(str(bill.amount_paid or 0))
                if balance > 0:
                    pending.append((bill, balance))
            if not pending:
                return "You have no pending maintenance balance."
            lines = ["Your pending maintenance:"]
            for bill, balance in pending[:5]:
                due = bill.due_date.strftime("%d-%m-%Y") if bill.due_date else "No due date"
                lines.append(f"• Bill #{bill.id}: ₹{balance:.2f} pending, due {due}, status {bill.status}.")
            return "\n".join(lines)

        if "recent complaints" in q or ("complaints" in q and any(k in q for k in ("show", "list", "my"))):
            query = self.db.query(Complaint).filter(Complaint.organization_id == user.organization_id)
            if user.role == "RESIDENT" and resident:
                query = query.filter(Complaint.resident_id == resident.id)
            elif user.role == "RESIDENT":
                return "I could not find your resident profile."
            rows = query.order_by(Complaint.created_at.desc()).limit(10).all()
            if not rows:
                return "No complaints found."
            return "Recent complaints:\n" + "\n".join(
                f"• #{c.id} {c.title} — {c.status} ({c.priority})" for c in rows
            )

        if "pending complaints" in q:
            if user.role == "RESIDENT":
                return "You can view your own complaints, but not the community-wide pending complaint list."
            if user.role not in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "BLOCK_ADMIN"}:
                return "You do not have permission to view community-wide pending complaints."
            rows = (self.db.query(Complaint)
                    .filter(Complaint.organization_id == user.organization_id,
                            Complaint.status.in_(["OPEN", "ASSIGNED", "IN_PROGRESS"]))
                    .order_by(Complaint.created_at.desc()).limit(15).all())
            return ("No pending complaints." if not rows else
                    "Pending complaints:\n" + "\n".join(
                        f"• #{c.id} {c.title} — {c.status} ({c.priority})" for c in rows))

        if "deliveries" in q and any(k in q for k in ("show", "my", "recent", "pending")):
            query = self.db.query(Delivery)
            if user.role == "RESIDENT":
                if not resident: return "I could not find your resident profile."
                query = query.filter(Delivery.resident_id == resident.id)
            else:
                query = (query.join(Resident, Delivery.resident_id == Resident.id)
                         .join(User, Resident.user_id == User.id)
                         .filter(User.organization_id == user.organization_id))
            rows = query.order_by(Delivery.created_at.desc()).limit(10).all()
            if not rows: return "No deliveries found."
            return "Deliveries:\n" + "\n".join(
                f"• #{d.id} {d.courier_name} — {d.status}" for d in rows)

        if "visitor" in q and any(k in q for k in ("who", "show", "today", "expected", "pending")):
            query = self.db.query(Visitor).join(Resident, Visitor.resident_id == Resident.id).join(User, Resident.user_id == User.id)
            if user.role == "RESIDENT":
                if not resident: return "I could not find your resident profile."
                query = query.filter(Visitor.resident_id == resident.id)
            else:
                query = query.filter(User.organization_id == user.organization_id)
            rows = query.order_by(Visitor.expected_time.asc().nullslast(), Visitor.created_at.desc()).limit(10).all()
            if not rows: return "No visitor records found."
            return "Visitor records:\n" + "\n".join(
                f"• #{v.id} {v.visitor_name} — {v.status}" +
                (f", expected {v.expected_time}" if v.expected_time else "")
                for v in rows)

        if "community chat" in q and any(k in q for k in ("open", "go", "take me")):
            return "OPEN_COMMUNITY_CHAT"
        return None

    def chat(self, user: User, messages):
        local = self._local_intent_response(user, " ".join(m.content for m in messages[-3:]))
        if local is not None:
            return local

        api_key = settings.GEMINI_API_KEY
        if not api_key:
            raise BadRequestException(
                "Gemini API is not configured. Add GEMINI_API_KEY to backend/.env and restart the server."
            )

        prompt_messages = messages[-20:]
        system_instruction = self._system_instruction(user)
        contents = []

        for item in prompt_messages:
            role = "user" if item.role == "user" else "model"
            contents.append(
                {
                    "role": role,
                    "parts": [{"text": item.content.strip()}],
                }
            )

        payload = {
            "system_instruction": {
                "parts": [{"text": system_instruction}],
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.35,
                "maxOutputTokens": 1200,
            },
        }

        model = settings.GEMINI_MODEL
        url = (
            "https://generativelanguage.googleapis.com/v1beta/"
            f"models/{model}:generateContent"
        )

        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                body = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            try:
                error_body = exc.read().decode("utf-8")
            except Exception:
                error_body = ""
            logger.error("Gemini API HTTP %s: %s", exc.code, error_body)
            if exc.code in (401, 403):
                raise BadRequestException(
                    "Gemini API rejected the API key. Check GEMINI_API_KEY."
                )
            raise BadRequestException(
                "Gemini API request failed. Please try again."
            )
        except (urllib.error.URLError, TimeoutError) as exc:
            logger.error("Gemini API network/timeout failure: %s", exc)
            raise BadRequestException(
                "The AI provider could not be reached. SafeColony data services are still available; please try again."
            )
        except Exception as exc:
            logger.exception("Unexpected AI provider failure")
            raise BadRequestException(
                f"AI service error: {type(exc).__name__}. Please try again."
            )
        text = self._extract_text(body)
        if not text:
            logger.warning("Gemini returned no text: %s", body)
            raise BadRequestException(
                "Gemini returned an empty response. Please try again."
            )

        return text.strip()

    def _system_instruction(self, user: User) -> str:
        role = user.role
        context = self._build_context(user)

        role_guidance = {
            "ORGANIZATION_ADMIN": """
You are the SafeColony AI Assistant for an organization administrator.
Help with residents, properties, units, security guards, visitors, deliveries,
notifications, vacations, maintenance/money management, reports, and community
operations. Give concise, practical administrative guidance. Never invent a live
number or status that is not present in the supplied context.
""",
            "SECURITY_MANAGER": """
You are the SafeColony AI Assistant for a security manager.
Focus on security operations, visitors, deliveries, alerts, vacations, guard
workflows, and community safety. Give actionable operational guidance. Never
invent a live number or status that is not present in the supplied context.
""",
            "SECURITY_GUARD": """
You are the SafeColony AI Assistant for a security guard.
Focus on visitor verification, QR/entry procedures, deliveries, residents,
vacation alerts, notifications, and safe security operations. Give short,
practical instructions suitable for a guard at the gate. Never invent a live
number or status that is not present in the supplied context.
""",
            "RESIDENT": """
You are the SafeColony AI Assistant for a resident.
Help with visitors, deliveries, maintenance payments, vacation mode,
notifications, profile/community workflows, and general SafeColony usage.
Give simple step-by-step guidance. Never invent a live amount, date, or status
that is not present in the supplied context.
""",
            "PROPERTY_MANAGER": """
You are the SafeColony AI Assistant for a property manager.
Focus on property, unit, resident, maintenance, visitor and operational
workflows. Never invent a live number or status that is not present in context.
""",
            "SYSTEM_ADMIN": """
You are the SafeColony AI Assistant for a system administrator.
Explain SafeColony administration, configuration, roles, permissions and
operational workflows. Do not expose secrets, tokens or API keys.
""",
        }.get(role, "You are the SafeColony AI Assistant. Help the user use SafeColony safely.")

        return (
            "You are SafeColony AI, a professional residential community assistant.\n"
            f"Current user: {user.full_name}. Role: {role}.\n"
            f"Current local date/time: {datetime.now(ZoneInfo(settings.APP_TIMEZONE)).isoformat()}.\n"
            "Do not reveal API keys, passwords, tokens, internal security secrets, "
            "or private data belonging to other users. If a request needs an action "
            "that the current app does not support, say so clearly instead of pretending "
            "that you performed it.\n"
            "SafeColony is India-first: use Asia/Kolkata (IST, UTC+05:30) for all user-facing dates and times. "
            "Use Indian Rupees (INR, ₹) for every monetary amount. Never display dollars ($), USD, or another currency "
            "unless the user explicitly asks for a different currency. Convert timestamps only for presentation; do not "
            "change the underlying database values. "
            "The LIVE SAFEColony CONTEXT below is authoritative database data. "
            "For factual questions about counts, notifications, incidents, alerts, "
            "maintenance, complaints, visitors or deliveries, use those values exactly. "
            "Do not substitute estimates, old conversation values or general knowledge. "
            "If a count is 0, explicitly say 0. If a requested detail is present in the "
            "detail lists, give the actual ID/title/status/severity/location/amount. "
            "Only say that specific details are unavailable when the corresponding field "
            "is actually absent from the supplied context. Distinguish unread notifications "
            "for the CURRENT USER from community security alerts and open incidents.\n\n"
            + role_guidance.strip()
            + "\n\nLIVE SAFEColony CONTEXT:\n"
            + context
        )

    def _build_context(self, user: User) -> str:
        organization_id = user.organization_id
        lines = [f"organization_id={organization_id}"]

        if not organization_id:
            return "No organization context is available."

        if user.role in {
            "ORGANIZATION_ADMIN",
            "PROPERTY_MANAGER",
            "SYSTEM_ADMIN",
        }:
            resident_count = (
                self.db.query(func.count(Resident.id))
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Resident.is_active.is_(True),
                )
                .scalar()
                or 0
            )
            guard_count = (
                self.db.query(func.count(User.id))
                .filter(
                    User.organization_id == organization_id,
                    User.role.in_(["SECURITY_GUARD", "SECURITY_MANAGER"]),
                    User.is_active.is_(True),
                )
                .scalar()
                or 0
            )
            pending_visitors = (
                self.db.query(func.count(Visitor.id))
                .join(Resident, Visitor.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Visitor.status == "PENDING",
                )
                .scalar()
                or 0
            )
            pending_deliveries = (
                self.db.query(func.count(Delivery.id))
                .join(Resident, Delivery.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
                )
                .scalar()
                or 0
            )
            lines.extend(
                [
                    f"active_residents={resident_count}",
                    f"active_security_staff={guard_count}",
                    f"pending_visitors={pending_visitors}",
                    f"pending_deliveries={pending_deliveries}",
                ]
            )

            period = (
                self.db.query(MaintenancePeriod)
                .filter(MaintenancePeriod.organization_id == organization_id)
                .order_by(MaintenancePeriod.month.desc())
                .first()
            )
            if period:
                collected = (
                    self.db.query(func.coalesce(func.sum(MaintenanceBill.amount_paid), 0))
                    .filter(MaintenanceBill.period_id == period.id)
                    .scalar()
                    or Decimal("0")
                )
                expenses = (
                    self.db.query(func.coalesce(func.sum(MaintenanceExpense.amount), 0))
                    .filter(MaintenanceExpense.period_id == period.id)
                    .scalar()
                    or Decimal("0")
                )
                unpaid = (
                    self.db.query(func.count(MaintenanceBill.id))
                    .filter(
                        MaintenanceBill.period_id == period.id,
                        MaintenanceBill.status.in_(["UNPAID", "PARTIAL"]),
                    )
                    .scalar()
                    or 0
                )
                lines.extend(
                    [
                        f"latest_maintenance_month={period.month}",
                        f"maintenance_monthly_amount={period.monthly_amount}",
                        f"maintenance_collected={collected}",
                        f"maintenance_unpaid_or_partial_bills={unpaid}",
                    ]
                )

        elif user.role == "RESIDENT":
            resident = ResidentRepository(self.db).get_by_user_id(user.id)
            if resident:
                lines.extend(
                    [
                        f"resident_id={resident.id}",
                        f"unit_number={resident.unit_number or 'not assigned'}",
                    ]
                )
                bill = (
                    self.db.query(MaintenanceBill)
                    .filter(MaintenanceBill.resident_id == resident.id)
                    .order_by(MaintenanceBill.due_date.desc())
                    .first()
                )
                if bill:
                    balance = Decimal(str(bill.total_due)) - Decimal(str(bill.amount_paid))
                    lines.extend(
                        [
                            f"latest_maintenance_status={bill.status}",
                            f"latest_maintenance_balance={balance}",
                            f"latest_maintenance_due_date={bill.due_date}",
                        ]
                    )
                active_vacation = (
                    self.db.query(VacationMode)
                    .filter(
                        VacationMode.resident_id == resident.id,
                        VacationMode.status == "ACTIVE",
                    )
                    .first()
                )
                lines.append(
                    "vacation_mode=ACTIVE" if active_vacation else "vacation_mode=INACTIVE"
                )
                pending_deliveries = (
                    self.db.query(func.count(Delivery.id))
                    .filter(
                        Delivery.resident_id == resident.id,
                        Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
                    )
                    .scalar()
                    or 0
                )
                lines.append(f"pending_deliveries={pending_deliveries}")

        elif user.role in {"SECURITY_GUARD", "SECURITY_MANAGER"}:
            pending_visitors = (
                self.db.query(func.count(Visitor.id))
                .join(Resident, Visitor.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Visitor.status.in_(["PENDING", "APPROVED"]),
                )
                .scalar()
                or 0
            )
            visitors_inside = (
                self.db.query(func.count(Visitor.id))
                .join(Resident, Visitor.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Visitor.status == "CHECKED_IN",
                )
                .scalar()
                or 0
            )
            pending_deliveries = (
                self.db.query(func.count(Delivery.id))
                .join(Resident, Delivery.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
                )
                .scalar()
                or 0
            )
            active_vacations = (
                self.db.query(func.count(VacationMode.id))
                .join(Resident, VacationMode.resident_id == Resident.id)
                .join(User, Resident.user_id == User.id)
                .filter(
                    User.organization_id == organization_id,
                    VacationMode.status == "ACTIVE",
                )
                .scalar()
                or 0
            )
            lines.extend(
                [
                    f"pending_or_approved_visitors={pending_visitors}",
                    f"visitors_inside={visitors_inside}",
                    f"pending_deliveries={pending_deliveries}",
                    f"active_vacations={active_vacations}",
                ]
            )

        # Feed the same live dashboard intelligence into the chat assistant so
        # answers are based on what the user can currently see in SafeColony.
        try:
            overview = AIInsightsEngine(self.db).build(user)
            metrics = overview.get("metrics", {})
            finance = metrics.get("maintenance", {}) or {}
            lines.extend([
                "AUTHORITATIVE_CURRENT_USER_UNREAD_NOTIFICATIONS=" + str(metrics.get("current_user_unread_notifications", 0)),
                "AUTHORITATIVE_ACTIVE_SECURITY_ALERTS=" + str(metrics.get("active_security_alerts", 0)),
                "AUTHORITATIVE_HIGH_PRIORITY_SECURITY_ALERTS=" + str(metrics.get("high_priority_alerts", 0)),
                "AUTHORITATIVE_OPEN_INCIDENTS=" + str(metrics.get("open_incidents", 0)),
                "AUTHORITATIVE_INCIDENTS_TODAY=" + str(metrics.get("incidents_today", 0)),
                "AUTHORITATIVE_OPEN_COMPLAINTS=" + str(metrics.get("open_complaints", 0)),
                "AUTHORITATIVE_MAINTENANCE_MONTH=" + str(finance.get("month")),
                "AUTHORITATIVE_MAINTENANCE_COLLECTED=" + str(finance.get("collected", 0)),
                "AUTHORITATIVE_MAINTENANCE_EXPENSES=" + str(finance.get("expenses", 0)),
                "AUTHORITATIVE_MAINTENANCE_OUTSTANDING=" + str(finance.get("outstanding", 0)),
                "AUTHORITATIVE_MAINTENANCE_UNPAID_BILLS=" + str(finance.get("unpaid_bills", 0)),
            ])
            if user.role in {"ORGANIZATION_ADMIN", "PROPERTY_MANAGER", "SYSTEM_ADMIN"}:
                period = (
                    self.db.query(MaintenancePeriod)
                    .filter(MaintenancePeriod.organization_id == organization_id)
                    .order_by(MaintenancePeriod.month.desc())
                    .first()
                )
                if period:
                    lines.append(f"AUTHORITATIVE_MAINTENANCE_MONTHLY_AMOUNT={period.monthly_amount}")
            lines.append("AUTHORITATIVE_ACTIVE_INCIDENT_DETAILS=" + json.dumps(metrics.get("active_incident_details", []), default=str))
            lines.append("AUTHORITATIVE_ACTIVE_SECURITY_ALERT_DETAILS=" + json.dumps(metrics.get("active_security_alert_details", []), default=str))
            lines.append("AUTHORITATIVE_CURRENT_USER_NOTIFICATION_DETAILS=" + json.dumps(metrics.get("current_user_notifications", []), default=str))
            lines.append("AUTHORITATIVE_LIVE_AI_DASHBOARD_JSON=" + json.dumps(overview, default=str))
        except Exception as exc:
            logger.warning("Unable to build extended AI dashboard context: %s", exc)

        return "\n".join(lines)

    @staticmethod
    def _extract_text(body: dict) -> str:
        candidates = body.get("candidates") or []
        if not candidates:
            return ""
        content = candidates[0].get("content") or {}
        parts = content.get("parts") or []
        return "\n".join(
            part.get("text", "")
            for part in parts
            if part.get("text")
        )
