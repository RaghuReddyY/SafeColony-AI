class SecuritySummaryEngine:

    def generate(self, dashboard):

        score = 100

        summary = []

        recommendation = []

        if dashboard["active_alerts"] > 0:

            score -= dashboard["active_alerts"] * 10

            summary.append(
                f"{dashboard['active_alerts']} active security alerts."
            )

            recommendation.append(
                "Review unresolved alerts immediately."
            )

        if dashboard["vacation_homes"] > 0:

            score -= dashboard["vacation_homes"] * 5

            summary.append(
                f"{dashboard['vacation_homes']} vacation homes require monitoring."
            )

            recommendation.append(
                "Increase patrol frequency near vacation homes."
            )

        if dashboard["pending_visitors"] > 5:

            score -= 10

            summary.append(
                "High number of pending visitors."
            )

        if dashboard["visitors_inside"] > 20:

            score -= 10

            summary.append(
                "High visitor traffic detected."
            )

        if score >= 90:
            status = "SAFE"

        elif score >= 70:
            status = "ATTENTION"

        else:
            status = "CRITICAL"

        return {
            "community_status": status,
            "risk_score": score,
            "ai_summary": " ".join(summary)
            if summary
            else "Community operating normally.",

            "recommendation": " ".join(recommendation)
            if recommendation
            else "No action required.",
        }