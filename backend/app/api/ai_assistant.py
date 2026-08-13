from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.ai.assistant import AIAssistant
from app.ai.insights import AIInsightsEngine
from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.ai_assistant import AIChatRequest, AIChatResponse
from app.schemas.ai_insights import AIOverviewResponse
from app.schemas.ai_report import AIReportRequest, AIReportResponse
from app.security.permissions import Permissions

router = APIRouter(prefix="/ai", tags=["AI Assistant"])


@router.get(
    "/overview",
    response_model=AIOverviewResponse,
    dependencies=[Depends(require_permission(Permissions.AI_ASSISTANT))],
)
def overview(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return AIInsightsEngine(db).build(current_user)


@router.post(
    "/chat",
    response_model=AIChatResponse,
    dependencies=[Depends(require_permission(Permissions.AI_ASSISTANT))],
)
def chat(
    data: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    assistant = AIAssistant(db)
    return AIChatResponse(message=assistant.chat(current_user, data.messages))


@router.post(
    "/report",
    response_model=AIReportResponse,
    dependencies=[Depends(require_permission(Permissions.AI_ASSISTANT))],
)
def report(
    data: AIReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    overview = AIInsightsEngine(db).build(current_user)
    metrics = overview["metrics"]
    report_type = data.report_type.upper()
    role = current_user.role

    lines = []
    if report_type in {"DAILY", "COMMUNITY"}:
        lines.extend([
            f"Community activity: {metrics.get('visitors_today', 0)} visitors, {metrics.get('deliveries_today', 0)} deliveries, {metrics.get('incidents_today', 0)} incidents and {metrics.get('complaints_today', 0)} complaints today.",
            f"Security: {metrics.get('active_security_alerts', 0)} unresolved alerts, {metrics.get('high_priority_alerts', 0)} high/critical alerts and {metrics.get('open_incidents', 0)} open incidents.",
            f"Operations: {metrics.get('active_vacations', 0)} active vacations, {metrics.get('pending_amenity_bookings', 0)} pending amenity bookings and {metrics.get('unread_notifications', 0)} unread notifications.",
        ])
    if report_type in {"DAILY", "SECURITY", "GUARD"}:
        lines.extend([
            f"Gate/security workload: {metrics.get('visitors_pending', 0)} pending visitors, {metrics.get('visitors_approved', 0)} approved visitors, {metrics.get('visitors_inside', 0)} visitors inside and {metrics.get('deliveries_pending', 0)} pending deliveries.",
            f"Visitor vehicle activity today: {metrics.get('visitor_vehicles_today', 0)}.",
        ])
    if report_type in {"DAILY", "FINANCE", "COMMUNITY"} and role in {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}:
        finance = metrics.get("maintenance", {})
        lines.append(
            f"Maintenance finance: collected ₹{finance.get('collected', 0):.2f}, expenses ₹{finance.get('expenses', 0):.2f}, outstanding ₹{finance.get('outstanding', 0):.2f}, unpaid/partial bills {finance.get('unpaid_bills', 0)}."
        )
    if report_type == "RESIDENT":
        personal = metrics.get("personal", {})
        lines.extend([
            f"Unit: {personal.get('unit_number', 'Not assigned')}.",
            f"Pending visitors: {personal.get('my_pending_visitors', 0)}; pending deliveries: {personal.get('my_pending_deliveries', 0)}.",
            f"Maintenance: {personal.get('maintenance_status', 'No bill')} with balance ₹{personal.get('maintenance_balance', 0):.2f}.",
            f"Vacation Mode: {'ACTIVE' if personal.get('my_active_vacation') else 'INACTIVE'}; unread notifications: {personal.get('my_unread_notifications', 0)}.",
        ])

    content = "\n\n".join(lines) or "No report data is available for this role yet."
    return AIReportResponse(
        report_type=report_type,
        title=f"SafeColony AI {report_type.title()} Report",
        content=content,
        generated_at=datetime.utcnow().isoformat(),
    )
