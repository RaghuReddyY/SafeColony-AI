from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.ai.assistant import AIAssistant
from app.ai.insights import AIInsightsEngine
from app.auth.dependencies import get_current_user
from app.auth.permissions import require_permission
from app.database.dependency import get_db
from app.models.user import User
from app.schemas.ai_assistant import AIChatRequest, AIChatResponse, AIIntentRequest, AIIntentResponse, AIActionRequest, AIActionResponse
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


@router.post("/intent", response_model=AIIntentResponse, dependencies=[Depends(require_permission(Permissions.AI_ASSISTANT))])
def intent(data: AIIntentRequest, current_user: User = Depends(get_current_user)):
    text = data.message.lower()
    if any(k in text for k in ("vegetable", "grocery", "groceries", "milk", "food", "medicine", "order")):
        category = "MEDICINE" if "medicine" in text else ("VEGETABLES" if "vegetable" in text else "COMMUNITY_MARKETPLACE")
        return AIIntentResponse(intent="MARKETPLACE_ORDER", category=category, action="OPEN_COMMUNITY_MARKETPLACE", explanation="I detected a community shopping request. SafeColony will show available community days/vendors; payment or order placement requires your confirmation.")
    if any(k in text for k in ("plumber", "electrician", "car service", "bike service", "repair", "cleaning", "ac repair")):
        return AIIntentResponse(intent="SERVICE_REQUEST", category="COMMUNITY_SERVICE", action="CREATE_SERVICE_REQUEST", explanation="I detected a service request. SafeColony can create a request for a trusted community provider; any quotation/payment requires your confirmation.")
    if any(k in text for k in ("bill", "electricity", "water bill", "internet", "dth", "recharge")):
        return AIIntentResponse(intent="UTILITY_PAYMENT", category="UTILITY", action="OPEN_UTILITY_BILLS", explanation="I detected a utility payment request. SafeColony can show configured bills and payment status; payment requires your confirmation.")
    if any(k in text for k in ("complaint", "leak", "broken", "incident", "problem")):
        return AIIntentResponse(intent="COMMUNITY_ISSUE", category="INCIDENT_OR_COMPLAINT", action="CREATE_ISSUE", explanation="I detected a community issue. SafeColony can route it to the appropriate complaint/incident workflow.")
    return AIIntentResponse(intent="GENERAL_ASSISTANCE", action="CHAT", explanation="I will answer using your role and the live SafeColony context. I will not claim an action was completed unless the application actually performs it.")


@router.post("/action", response_model=AIActionResponse, dependencies=[Depends(require_permission(Permissions.AI_ASSISTANT))])
def action(data: AIActionRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    text=data.message.lower()
    if any(k in text for k in ("order", "grocery", "groceries", "milk", "vegetable", "medicine", "food")):
        from app.services.marketplace_service import MarketplaceService
        svc=MarketplaceService(db)
        event_id=data.event_id
        if event_id is None:
            events=svc.list_events(current_user)
            wanted = "medicine" if "medicine" in text else ("vegetable" if "vegetable" in text else "grocery")
            match=next((e for e in events if wanted in e["category"].lower() or wanted in e["title"].lower()), None)
            if match is None and events: match=events[0]
            event_id=match["id"] if match else None
        if event_id is None: raise HTTPException(status_code=404, detail="No open community day is available for this request.")
        items=data.items or []
        if not items:
            import re
            qty=float(re.search(r"(\d+(?:\.\d+)?)", text).group(1)) if re.search(r"(\d+(?:\.\d+)?)", text) else 1
            unit="litre" if "litre" in text or "liter" in text or "l " in text else ("kg" if "kg" in text else "unit")
            name="milk" if "milk" in text else ("vegetables" if "vegetable" in text else ("medicine" if "medicine" in text else "community item"))
            items=[{"name":name,"quantity":qty,"unit":unit,"unit_price":0}]
        preview=f"Place {len(items)} item(s) on community day #{event_id}."
        if not data.confirmed: return AIActionResponse(intent="MARKETPLACE_ORDER",action="CREATE_MARKETPLACE_ORDER",requires_confirmation=True,preview=preview)
        from app.schemas.marketplace import OrderCreate
        order=svc.place_order(current_user,event_id,OrderCreate(items=items))
        return AIActionResponse(intent="MARKETPLACE_ORDER",action="CREATE_MARKETPLACE_ORDER",requires_confirmation=False,preview="Order placed successfully.",result={"order_id":order.id,"event_id":event_id,"status":order.status})
    if any(k in text for k in ("plumber","electrician","repair","cleaning","car service","bike service","ac service")):
        from app.services.super_app_service import SuperAppService
        svc=SuperAppService(db)
        preview="Create a community service request and route it to a matching vendor."
        if not data.confirmed: return AIActionResponse(intent="SERVICE_REQUEST",action="CREATE_SERVICE_REQUEST",requires_confirmation=True,preview=preview)
        payload=data.service_request or {}
        from app.schemas.super_app import ServiceRequestCreate
        req=svc.create_request(current_user,ServiceRequestCreate(category=payload.get("category", "SERVICE"),title=payload.get("title", data.message[:150]),description=payload.get("description"),preferred_slot=payload.get("preferred_slot")))
        return AIActionResponse(intent="SERVICE_REQUEST",action="CREATE_SERVICE_REQUEST",requires_confirmation=False,preview="Service request created successfully.",result={"request_id":req["id"],"status":req["status"],"vendor_name":req.get("vendor_name")})
    return AIActionResponse(intent="GENERAL_ASSISTANCE",action="CHAT",requires_confirmation=False,preview="No executable SafeColony action was detected.",result=None)
