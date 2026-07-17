class GuardService:

    def __init__(self, repo):
        self.repo = repo

    # ==================================================
    # Public API
    # ==================================================

    def dashboard(self):

        # Fetch once and reuse
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

    def pending_visitors(self):
        return self.repo.pending_visitors()

    def visitors_inside(self):
        return self.repo.visitors_inside()

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

            "deliveries": 0,

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