from app.repositories.visitor_repository import VisitorRepository


class GuardDashboardService:

    def __init__(self, db):
        self.repo = VisitorRepository(db)

    def get_dashboard(self):

        expected_visitors = self.repo.get_expected_visitors()

        expected_count = self.repo.get_expected_visitor_count()

        checked_in_today = self.repo.get_checked_in_today_count()

        currently_inside = self.repo.get_currently_inside_count()

        messages = []

        if expected_count == 0:
            messages.append(
                "No visitors are expected."
            )
        elif expected_count == 1:
            messages.append(
                "1 visitor is waiting for entry."
            )
        else:
            messages.append(
                f"{expected_count} visitors are waiting for entry."
            )

        if checked_in_today == 0:
            messages.append(
                "No visitors have checked in today."
            )
        else:
            messages.append(
                f"{checked_in_today} visitor(s) checked in today."
            )

        if currently_inside == 0:
            messages.append(
                "No visitors are currently inside the community."
            )
        else:
            messages.append(
                f"{currently_inside} visitor(s) are currently inside."
            )

        return {
            "summary": {
                "expected_visitors": expected_count,
                "walk_in_requests": 0,
                "deliveries": 0,
                "vacant_houses": 0,
                "checked_in_today": checked_in_today,
                "currently_inside": currently_inside,
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
                for visitor in expected_visitors
            ],
            "ai_message": "\n\n".join(messages),
        }