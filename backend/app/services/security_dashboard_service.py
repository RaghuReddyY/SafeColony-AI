from app.ai.security_summary import SecuritySummaryEngine

from app.repositories.security_dashboard_repository import (
    SecurityDashboardRepository,
)


class SecurityDashboardService:

    def __init__(
        self,
        repo: SecurityDashboardRepository,
    ):
        self.repo = repo

        self.ai = SecuritySummaryEngine()

    def get_dashboard(self):

        dashboard = self.repo.get_dashboard()

        ai_result = self.ai.generate(dashboard)

        return {
            "active_alerts": dashboard["active_alerts"],
            "vacation_homes": dashboard["vacation_homes"],
            "visitors_inside": dashboard["visitors_inside"],
            "pending_visitors": dashboard["pending_visitors"],
            "vehicles_inside": dashboard["vehicles_inside"],
            "unread_notifications": dashboard["unread_notifications"],
            "latest_alerts": dashboard["latest_alerts"],

            "community_status": ai_result["community_status"],
            "risk_score": ai_result["risk_score"],
            "ai_summary": ai_result["ai_summary"],
            "recommendation": ai_result["recommendation"],
        }