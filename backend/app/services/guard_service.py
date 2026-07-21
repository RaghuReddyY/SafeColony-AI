from app.repositories.guard_repository import GuardRepository

from app.services.delivery_service import DeliveryService
from app.services.vehicle_service import VehicleService


class GuardService:

    def __init__(
        self,
        repo: GuardRepository,
    ):
        self.repo = repo

        self.delivery_service = DeliveryService(
            repo.delivery_repository
        )

        self.vehicle_service = VehicleService(
            repo.vehicle_repository
        )

    # ==================================================
    # Dashboard
    # ==================================================

    def dashboard(self):

        visitors = self.repo.today_expected_visitors()

        summary = self._summary(visitors)

        expected_visitors = self._expected_visitors(
            visitors
        )

        recent_activities = self._recent_activities()

        ai_message = self._ai_briefing(summary)

        return {

            "summary": summary,

            "expected_visitors": expected_visitors,

            "recent_activities": recent_activities,

            "ai_message": ai_message,
        }

    # ==================================================
    # Visitor Operations
    # ==================================================

    def pending_visitors(self):
        return self.repo.pending_visitors()

    def visitors_inside(self):
        return self.repo.visitors_inside()

    # ==================================================
    # Delivery Operations
    # ==================================================

    def pending_deliveries(self):
        return self.delivery_service.pending_deliveries()

    def receive_delivery(
        self,
        delivery_id: int,
        guard_name: str,
    ):
        return self.delivery_service.receive(
            delivery_id,
            guard_name,
        )

    def verify_delivery(
        self,
        delivery_id: int,
        otp: str,
    ):
        return self.delivery_service.verify_otp(
            delivery_id,
            otp,
        )

    # ==================================================
    # Vehicle Operations
    # ==================================================

    def pending_vehicles(self):
        return self.vehicle_service.pending_vehicles()

    def vehicle_entry(
        self,
        vehicle_id: int,
        guard_name: str,
    ):
        return self.vehicle_service.vehicle_entry(
            vehicle_id,
            guard_name,
        )

    def vehicle_exit(
        self,
        vehicle_id: int,
        guard_name: str,
    ):
        return self.vehicle_service.vehicle_exit(
            vehicle_id,
            guard_name,
        )

    # ==================================================
    # Dashboard Helpers
    # ==================================================

    def _summary(self, visitors):

        checked_in_today = (
            self.repo.today_checked_in_count()
        )

        return {

            "expected_visitors": len(visitors),

            "walk_in_requests": 0,

            "deliveries": len(
                self.delivery_service.pending_deliveries()
            ),

            "vacant_houses": 0,

            "checked_in_today": checked_in_today,
        }

    def _expected_visitors(self, visitors):

        return [

            {

                "id": visitor.id,

                "resident_id": visitor.resident_id,

                "visitor_name": visitor.visitor_name,

                "phone": visitor.phone,

                "visitor_type": visitor.visitor_type,

                "purpose": visitor.purpose,

                "vehicle_number": visitor.vehicle_number,

                "expected_time": (
                    visitor.expected_time.isoformat()
                    if visitor.expected_time
                    else None
                ),

                "status": visitor.status,
            }

            for visitor in visitors
        ]

    def _recent_activities(self):

        activities = []

        for visitor in self.repo.recent_activities():

            if visitor.status == "CHECKED_IN":

                activities.append({

                    "icon": "login",

                    "title":
                        f"{visitor.visitor_name} checked in",

                    "time":
                        visitor.check_in_time.strftime("%I:%M %p")
                        if visitor.check_in_time
                        else "-",
                })

            elif visitor.status == "CHECKED_OUT":

                activities.append({

                    "icon": "logout",

                    "title":
                        f"{visitor.visitor_name} checked out",

                    "time":
                        visitor.check_out_time.strftime("%I:%M %p")
                        if visitor.check_out_time
                        else "-",
                })

            elif visitor.status == "APPROVED":

                activities.append({

                    "icon": "verified",

                    "title":
                        f"{visitor.visitor_name} approved",

                    "time":
                        visitor.approved_at.strftime("%I:%M %p")
                        if visitor.approved_at
                        else "-",
                })

        return activities

    def _ai_briefing(self, summary):

        messages = []

        if summary["expected_visitors"] == 0:

            messages.append(
                "No visitors are expected today."
            )

        elif summary["expected_visitors"] == 1:

            messages.append(
                "1 visitor is expected today."
            )

        else:

            messages.append(
                f'{summary["expected_visitors"]} visitors are expected today.'
            )

        if summary["checked_in_today"] == 0:

            messages.append(
                "No visitors have checked in yet."
            )

        elif summary["checked_in_today"] == 1:

            messages.append(
                "1 visitor has already checked in."
            )

        else:

            messages.append(
                f'{summary["checked_in_today"]} visitors have already checked in.'
            )

        return "\n\n".join(messages)