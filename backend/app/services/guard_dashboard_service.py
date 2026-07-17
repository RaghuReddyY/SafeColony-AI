from app.repositories.visitor_repository import VisitorRepository


class GuardDashboardService:

    def __init__(self, db):
        self.repo = VisitorRepository(db)

    def get_dashboard(self):

        visitors = self.repo.get_expected_visitors()

        # ---------- AI Insight ----------
        messages = []

        if len(visitors) == 0:
            messages.append(
                "No visitors are expected today."
            )
        else:
            messages.append(
                f"{len(visitors)} visitor(s) expected today."
            )

        checked_in = self.repo.get_checked_in_today()

        if checked_in > 0:
            messages.append(
                f"{checked_in} visitor(s) already checked in."
            )
        else:
            messages.append(
                "No visitors have checked in yet."
            )

        ai_message = "\n\n".join(messages)

        # ---------- Dashboard Response ----------
        return {
            "summary": {
                "expected_visitors": len(visitors),
                "walk_in_requests": 0,
                "deliveries": 0,
                "vacant_houses": 0,
                "checked_in_today": checked_in,
            },
            "expected_visitors": [
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
            ],
            "ai_message": ai_message,
        }