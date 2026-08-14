from datetime import datetime, timedelta
import json
from urllib.parse import quote
from urllib.request import Request, urlopen

from sqlalchemy import func

from app.models.delivery import Delivery
from app.models.notification import Notification
from app.models.resident import Resident
from app.models.vacation_mode import VacationMode
from app.models.visitor import Visitor


class DashboardRepository:

    def __init__(self, db):
        self.db = db

    def _weather(self, city: str | None):
        """Return current weather for the organisation city when available.
        Weather failure never prevents the resident dashboard from loading.
        """
        if not city:
            return None, None, None

        try:
            geo_url = (
                "https://geocoding-api.open-meteo.com/v1/search?name="
                f"{quote(city)}&count=1&language=en&format=json"
            )
            request = Request(
                geo_url,
                headers={"User-Agent": "SafeColony-AI/1.0"},
            )
            with urlopen(request, timeout=3) as response:
                geo = json.loads(response.read().decode("utf-8"))

            results = geo.get("results") or []
            if not results:
                return None, city, None

            latitude = results[0]["latitude"]
            longitude = results[0]["longitude"]

            weather_url = (
                "https://api.open-meteo.com/v1/forecast?"
                f"latitude={latitude}&longitude={longitude}"
                "&current=temperature_2m,weather_code"
                "&timezone=auto"
            )
            request = Request(
                weather_url,
                headers={"User-Agent": "SafeColony-AI/1.0"},
            )
            with urlopen(request, timeout=3) as response:
                weather = json.loads(response.read().decode("utf-8"))

            current = weather.get("current") or {}
            temperature = current.get("temperature_2m")
            code = current.get("weather_code")

            descriptions = {
                0: "Clear sky",
                1: "Mainly clear",
                2: "Partly cloudy",
                3: "Overcast",
                45: "Foggy",
                48: "Rime fog",
                51: "Light drizzle",
                53: "Drizzle",
                55: "Heavy drizzle",
                61: "Light rain",
                63: "Rain",
                65: "Heavy rain",
                71: "Light snow",
                73: "Snow",
                75: "Heavy snow",
                80: "Rain showers",
                81: "Rain showers",
                82: "Heavy rain showers",
                95: "Thunderstorm",
                96: "Thunderstorm with hail",
                99: "Thunderstorm with hail",
            }

            return temperature, city, descriptions.get(code, "Current conditions")
        except Exception:
            return None, city, None

    def get_summary(self, user_id: int):
        resident = (
            self.db.query(Resident)
            .filter(Resident.user_id == user_id)
            .first()
        )

        if resident is None:
            return None

        resident_id = resident.id

        visitor_count = (
            self.db.query(func.count(Visitor.id))
            .filter(Visitor.resident_id == resident_id)
            .scalar()
            or 0
        )

        pending_visitors = (
            self.db.query(func.count(Visitor.id))
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.status == "PENDING",
            )
            .scalar()
            or 0
        )

        delivery_count = (
            self.db.query(func.count(Delivery.id))
            .filter(Delivery.resident_id == resident_id)
            .scalar()
            or 0
        )

        pending_deliveries = (
            self.db.query(func.count(Delivery.id))
            .filter(
                Delivery.resident_id == resident_id,
                Delivery.status.in_(["ARRIVED", "NOTIFIED"]),
            )
            .scalar()
            or 0
        )

        notification_count = (
            self.db.query(func.count(Notification.id))
            .filter(Notification.user_id == user_id)
            .scalar()
            or 0
        )

        unread_notifications = (
            self.db.query(func.count(Notification.id))
            .filter(
                Notification.user_id == user_id,
                Notification.is_read == False,
            )
            .scalar()
            or 0
        )

        vacation = (
            self.db.query(VacationMode)
            .filter(
                VacationMode.resident_id == resident_id,
                VacationMode.status == "ACTIVE",
            )
            .first()
        )
        vacation_mode = vacation is not None

        security_score = 100
        security_score -= pending_visitors * 2
        security_score -= pending_deliveries
        security_score -= unread_notifications

        if vacation_mode:
            security_score += 2
            if vacation.monitoring_enabled:
                security_score += 2

        security_score = max(0, min(100, security_score))
        community_status = (
            "Secure" if security_score >= 80 else "Needs Attention"
        )

        # Monday=0 ... Sunday=6. Use UTC because the existing audit fields
        # are stored as UTC datetimes.
        now = datetime.utcnow()
        start_of_week = datetime(
            now.year,
            now.month,
            now.day,
        ) - timedelta(days=now.weekday())
        end_of_week = start_of_week + timedelta(days=7)

        weekly_rows = (
            self.db.query(
                func.date(Visitor.created_at),
                func.count(Visitor.id),
            )
            .filter(
                Visitor.resident_id == resident_id,
                Visitor.created_at >= start_of_week,
                Visitor.created_at < end_of_week,
            )
            .group_by(func.date(Visitor.created_at))
            .all()
        )

        weekly_visitors = [0] * 7
        for day_value, count in weekly_rows:
            if day_value is None:
                continue
            if hasattr(day_value, "weekday"):
                weekday = day_value.weekday()
            else:
                weekday = datetime.strptime(
                    str(day_value), "%Y-%m-%d"
                ).weekday()
            weekly_visitors[weekday] = int(count)

        recent_notifications = (
            self.db.query(Notification)
            .filter(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(5)
            .all()
        )

        recent_activity = [
            {
                "title": notification.title,
                "message": notification.message,
                "notification_type": notification.notification_type,
                "created_at": notification.created_at,
                "is_read": notification.is_read,
            }
            for notification in recent_notifications
        ]

        if pending_visitors > 0:
            recommendation = (
                f"You have {pending_visitors} pending visitor"
                f"{'s' if pending_visitors != 1 else ''}. "
                "Review them before their expected arrival."
            )
        elif pending_deliveries > 0:
            recommendation = (
                f"You have {pending_deliveries} delivery"
                f"{'s' if pending_deliveries != 1 else ''} waiting at the gate."
            )
        elif vacation_mode:
            recommendation = (
                "Vacation Mode is active. Your configured visitor and "
                "delivery policies are being followed."
            )
        elif unread_notifications > 0:
            recommendation = (
                f"You have {unread_notifications} unread notification"
                f"{'s' if unread_notifications != 1 else ''}. "
                "Review them when convenient."
            )
        else:
            recommendation = (
                "Everything looks up to date. Your community dashboard "
                "has no immediate action for you."
            )

        organization = getattr(
            getattr(resident, "user", None),
            "organization",
            None,
        )
        city = getattr(organization, "city", None)
        temperature, weather_city, weather_description = self._weather(city)

        return {
            "resident_name": resident.full_name or "Resident",
            "unit_number": resident.unit_number or "Not Assigned",
            "section_name": resident.section_name,
            "organization_name": getattr(organization, "name", None),
            "organization_code": getattr(organization, "organization_code", None),
            "visitor_count": int(visitor_count),
            "pending_visitors": int(pending_visitors),
            "delivery_count": int(delivery_count),
            "pending_deliveries": int(pending_deliveries),
            "notification_count": int(notification_count),
            "unread_notifications": int(unread_notifications),
            "vacation_mode": vacation_mode,
            "security_score": int(security_score),
            "weekly_visitors": weekly_visitors,
            "recent_activity": recent_activity,
            "recommendation": recommendation,
            "weather_temperature": temperature,
            "weather_city": weather_city,
            "weather_description": weather_description,
            "community_status": community_status,
        }
