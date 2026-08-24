from datetime import datetime
from secrets import token_hex
from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import joinedload

from app.models.user import User
from app.models.community_service import CommunityService
from app.models.marketplace import MarketplaceVendor, MarketplaceEvent, MarketplaceOrder
from app.models.resident import Resident
from app.models.notification import Notification
from app.models.super_app import (
    ServiceRequest, VendorOffer, VendorRating, CommunityParcel, UtilityBill, RecurringOrder,
    UtilityProvider, CommunityMapPoint,
)


ADMIN_ROLES = {"SYSTEM_ADMIN", "ORGANIZATION_ADMIN", "PROPERTY_MANAGER"}


class SuperAppService:
    def __init__(self, db):
        self.db = db

    def org(self, user):
        if not user.organization_id:
            raise HTTPException(400, "User is not associated with an organization.")
        return user.organization_id

    def _require_admin(self, user):
        if user.role not in ADMIN_ROLES:
            raise HTTPException(403, "Only community administrators can manage this feature.")

    def overview(self, user):
        org = self.org(user)
        services = self.db.query(CommunityService).filter_by(organization_id=org, is_active=True).order_by(CommunityService.category).all()
        events = self.db.query(MarketplaceEvent).filter_by(organization_id=org, is_active=True, status="OPEN").order_by(MarketplaceEvent.scheduled_for).limit(8).all()
        total = self.db.query(func.count(CommunityParcel.id)).filter_by(organization_id=org).scalar() or 0
        hub = self.db.query(func.count(CommunityParcel.id)).filter_by(organization_id=org, status="AT_HUB").scalar() or 0
        picked = self.db.query(func.count(CommunityParcel.id)).filter_by(organization_id=org, status="PICKED_UP").scalar() or 0
        pending = self.db.query(func.count(ServiceRequest.id)).filter(ServiceRequest.organization_id == org, ServiceRequest.status.in_(["REQUESTED", "ASSIGNED", "QUOTED", "APPROVED", "IN_PROGRESS"])).scalar() or 0
        recurring = self.db.query(func.count(RecurringOrder.id)).filter_by(organization_id=org, active=True).scalar() or 0
        utilities = []
        if user.role == "RESIDENT":
            utilities = [{
                "type": u.utility_type,
                "provider": u.provider_name,
                "amount": float(u.amount),
                "due_date": u.due_date.isoformat() if u.due_date else None,
                "status": u.status,
            } for u in self.db.query(UtilityBill).filter_by(organization_id=org, resident_user_id=user.id).order_by(UtilityBill.due_date).limit(10)]
        providers = self.db.query(UtilityProvider).filter_by(organization_id=org).order_by(UtilityProvider.utility_type, UtilityProvider.name).all()
        if user.role == "RESIDENT":
            providers = [p for p in providers if p.is_active and p.status == "ACTIVE"]
        points = self.db.query(CommunityMapPoint).filter_by(organization_id=org, is_active=True).order_by(CommunityMapPoint.point_type, CommunityMapPoint.name).all()
        return {
            "role": user.role,
            "services": [{"id": s.id, "name": s.name, "category": s.category, "phone": s.phone, "description": s.work_description} for s in services],
            "marketplace_categories": sorted({e.category for e in events}),
            "upcoming_community_days": [{"id": e.id, "title": e.title, "category": e.category, "scheduled_for": e.scheduled_for.isoformat() if e.scheduled_for else None, "cutoff_at": e.cutoff_at.isoformat() if e.cutoff_at else None, "vendor": e.vendor.name if e.vendor else None} for e in events],
            "hub": {"total_parcels": total, "at_hub": hub, "picked_up": picked, "pending_requests": pending, "active_recurring_orders": recurring},
            "utilities": utilities,
            "supported_utility_providers": providers,
            "map_points": points,
        }

    def service_providers(self, user, category=None):
        org = self.org(user)
        normalized = category.strip().upper() if category else None
        cq = self.db.query(CommunityService).filter_by(organization_id=org, is_active=True)
        vq = self.db.query(MarketplaceVendor).filter_by(organization_id=org, is_active=True)
        if normalized:
            cq = cq.filter(func.upper(CommunityService.category) == normalized)
            vq = vq.filter(func.upper(MarketplaceVendor.category) == normalized)
        rows = []
        for provider in cq.order_by(CommunityService.name).all():
            rows.append({"id": provider.id, "provider_type": "COMMUNITY_SERVICE", "name": provider.name, "category": provider.category, "phone": provider.phone, "description": provider.work_description, "provider_id": provider.id, "vendor_id": None})
        for vendor in vq.order_by(MarketplaceVendor.name).all():
            rows.append({"id": vendor.id, "provider_type": "VENDOR", "name": vendor.name, "category": vendor.category, "phone": vendor.phone, "description": vendor.notes, "provider_id": None, "vendor_id": vendor.id})
        return rows

    def create_request(self, user, data):
        org = self.org(user)
        if data.provider_id and not self.db.query(CommunityService).filter_by(id=data.provider_id, organization_id=org, is_active=True).first():
            raise HTTPException(404, "Service provider not found.")
        vendor = None
        vendor_id = data.vendor_id
        if vendor_id is not None:
            vendor = self.db.query(MarketplaceVendor).filter_by(id=vendor_id, organization_id=org, is_active=True).first()
            if not vendor:
                raise HTTPException(404, "Vendor not found.")
        elif data.provider_id is None:
            matches = self.db.query(MarketplaceVendor).filter(
                MarketplaceVendor.organization_id == org,
                MarketplaceVendor.is_active.is_(True),
                func.upper(MarketplaceVendor.category) == data.category.strip().upper(),
            ).order_by(MarketplaceVendor.name).all()
            if len(matches) == 1:
                vendor = matches[0]
                vendor_id = vendor.id
        obj = ServiceRequest(
            organization_id=org, resident_user_id=user.id, provider_id=data.provider_id, vendor_id=vendor_id,
            category=data.category.strip().upper(), title=data.title.strip(), description=data.description, preferred_slot=data.preferred_slot,
        )
        self.db.add(obj)
        self.db.flush()
        if vendor and vendor.user_id:
            self.db.add(Notification(
                user_id=vendor.user_id,
                title="New service request",
                message=f"{user.full_name} requested {obj.title}. Open Vendor Portal to accept, quote or reject the request.",
                notification_type="SERVICE_REQUEST",
            ))
        self.db.commit()
        self.db.refresh(obj)
        return self.request_response(obj)

    def list_requests(self, user):
        org = self.org(user)
        q = self.db.query(ServiceRequest).options(joinedload(ServiceRequest.provider), joinedload(ServiceRequest.resident_user), joinedload(ServiceRequest.vendor)).filter_by(organization_id=org)
        if user.role == "RESIDENT":
            q = q.filter_by(resident_user_id=user.id)
        return [self.request_response(x) for x in q.order_by(ServiceRequest.created_at.desc()).all()]

    def vendor_requests(self, user):
        org = self.org(user)
        vendor = self.db.query(MarketplaceVendor).filter_by(organization_id=org, user_id=user.id, is_active=True).first()
        if not vendor:
            raise HTTPException(403, "Your account is not linked to a SafeColony vendor.")
        q = self.db.query(ServiceRequest).options(joinedload(ServiceRequest.resident_user), joinedload(ServiceRequest.vendor)).filter(ServiceRequest.organization_id == org, ServiceRequest.vendor_id == vendor.id)
        return [self.request_response(x) for x in q.order_by(ServiceRequest.created_at.desc()).all()]

    def vendor_update_request(self, user, rid, data):
        org = self.org(user)
        vendor = self.db.query(MarketplaceVendor).filter_by(organization_id=org, user_id=user.id, is_active=True).first()
        if not vendor:
            raise HTTPException(403, "Your account is not linked to a SafeColony vendor.")
        obj = self.db.query(ServiceRequest).options(joinedload(ServiceRequest.resident_user)).filter_by(id=rid, organization_id=org, vendor_id=vendor.id).first()
        if not obj:
            raise HTTPException(404, "Service request not found.")
        allowed = {
            "REQUESTED": {"ASSIGNED", "CANCELLED"},
            "ASSIGNED": {"QUOTED", "IN_PROGRESS", "CANCELLED"},
            "QUOTED": {"IN_PROGRESS", "CANCELLED"},
            "APPROVED": {"IN_PROGRESS", "CANCELLED"},
            "IN_PROGRESS": {"COMPLETED", "CANCELLED"},
            "COMPLETED": set(),
            "CANCELLED": set(),
        }
        if data.status not in allowed.get(obj.status, set()):
            raise HTTPException(400, f"Cannot change service request from {obj.status} to {data.status}.")
        if data.status == "QUOTED" and data.quoted_amount is None:
            raise HTTPException(400, "A quote amount is required before sending a quote.")
        obj.status = data.status
        if data.quoted_amount is not None:
            obj.quoted_amount = data.quoted_amount
        self.db.add(Notification(
            user_id=obj.resident_user_id,
            title="Service request updated",
            message=f"Your service request '{obj.title}' is now {obj.status}." + (f" Quote: ₹{obj.quoted_amount}" if obj.status == "QUOTED" else ""),
            notification_type="SERVICE_REQUEST",
        ))
        self.db.commit(); self.db.refresh(obj)
        return self.request_response(obj)

    def update_request(self, user, rid, data):
        org = self.org(user)
        q = self.db.query(ServiceRequest).options(joinedload(ServiceRequest.vendor)).filter_by(id=rid, organization_id=org)
        if user.role == "RESIDENT":
            q = q.filter_by(resident_user_id=user.id)
        obj = q.first()
        if not obj:
            raise HTTPException(404, "Service request not found.")
        if user.role == "RESIDENT":
            if data.status not in {"APPROVED", "CANCELLED"}:
                raise HTTPException(403, "Residents can only approve a quote or cancel their request.")
            if data.status == "APPROVED" and obj.status != "QUOTED":
                raise HTTPException(400, "Only a quoted request can be approved.")
        elif user.role not in ADMIN_ROLES:
            raise HTTPException(403, "You do not have permission to update this service request.")
        obj.status = data.status
        if data.quoted_amount is not None: obj.quoted_amount = data.quoted_amount
        if obj.vendor and obj.vendor.user_id and user.role == "RESIDENT":
            self.db.add(Notification(
                user_id=obj.vendor.user_id,
                title="Service request response",
                message=f"Resident {user.full_name} changed '{obj.title}' to {obj.status}.",
                notification_type="SERVICE_REQUEST",
            ))
        self.db.commit(); self.db.refresh(obj)
        return self.request_response(obj)

    def request_response(self, x):
        return {
            "id": x.id, "category": x.category, "title": x.title, "description": x.description, "preferred_slot": x.preferred_slot,
            "status": x.status, "quoted_amount": x.quoted_amount, "payment_status": x.payment_status,
            "provider_id": x.provider_id, "provider_name": x.provider.name if x.provider else None,
            "vendor_id": x.vendor_id, "vendor_name": x.vendor.name if x.vendor else None, "created_at": x.created_at,
        }

    def offers(self, user):
        return self.db.query(VendorOffer).filter_by(organization_id=self.org(user), is_active=True).order_by(VendorOffer.created_at.desc()).all()

    def create_offer(self, user, data):
        org = self.org(user)
        if not self.db.query(MarketplaceVendor).filter_by(id=data.vendor_id, organization_id=org).first():
            raise HTTPException(404, "Vendor not found.")
        obj = VendorOffer(organization_id=org, **data.model_dump())
        self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def rate(self, user, data):
        org = self.org(user)
        if not self.db.query(MarketplaceVendor).filter_by(id=data.vendor_id, organization_id=org).first(): raise HTTPException(404, "Vendor not found.")
        if data.order_id and not self.db.query(MarketplaceOrder).filter_by(id=data.order_id, organization_id=org, resident_user_id=user.id).first(): raise HTTPException(403, "Order does not belong to you.")
        obj = VendorRating(organization_id=org, resident_user_id=user.id, **data.model_dump()); self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def recurring(self, user, data):
        obj = RecurringOrder(organization_id=self.org(user), resident_user_id=user.id, **data.model_dump()); self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def list_recurring(self, user):
        return self.db.query(RecurringOrder).filter_by(organization_id=self.org(user), resident_user_id=user.id).order_by(RecurringOrder.created_at.desc()).all()

    def create_parcel(self, user, data):
        org = self.org(user)
        order = self.db.query(MarketplaceOrder).filter_by(id=data.order_id, organization_id=org).first()
        if not order: raise HTTPException(404, "Order not found.")
        existing = self.db.query(CommunityParcel).filter_by(order_id=order.id).first()
        if existing: return existing
        obj = CommunityParcel(organization_id=org, order_id=data.order_id, apartment_label=data.apartment_label, hub=data.hub, pickup_code=token_hex(3).upper())
        self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def parcels(self, user):
        q = self.db.query(CommunityParcel).filter_by(organization_id=self.org(user))
        if user.role == "RESIDENT":
            q = q.join(MarketplaceOrder, CommunityParcel.order_id == MarketplaceOrder.id).filter(MarketplaceOrder.resident_user_id == user.id)
        return q.order_by(CommunityParcel.created_at.desc()).limit(100).all()

    def pickup(self, user, pid):
        obj = self.db.query(CommunityParcel).filter_by(id=pid, organization_id=self.org(user)).first()
        if not obj: raise HTTPException(404, "Parcel not found.")
        if user.role == "RESIDENT":
            order = self.db.query(MarketplaceOrder).filter_by(id=obj.order_id, organization_id=obj.organization_id, resident_user_id=user.id).first()
            if not order: raise HTTPException(403, "You cannot pick up this parcel.")
        if obj.status != "AT_HUB": raise HTTPException(400, "This parcel is not waiting at the hub.")
        obj.status = "PICKED_UP"; obj.handed_to_user_id = user.id; obj.picked_up_at = datetime.utcnow(); self.db.commit(); self.db.refresh(obj); return obj

    def utility_providers(self, user):
        org = self.org(user)
        q = self.db.query(UtilityProvider).filter_by(organization_id=org)
        if user.role == "RESIDENT": q = q.filter(UtilityProvider.is_active.is_(True), UtilityProvider.status == "ACTIVE")
        return q.order_by(UtilityProvider.utility_type, UtilityProvider.name).all()

    def create_utility_provider(self, user, data):
        self._require_admin(user)
        obj = UtilityProvider(organization_id=self.org(user), **data.model_dump())
        self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def update_utility_provider(self, user, provider_id, data):
        self._require_admin(user)
        obj = self.db.query(UtilityProvider).filter_by(id=provider_id, organization_id=self.org(user)).first()
        if not obj: raise HTTPException(404, "Utility provider not found.")
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(obj, key, value)
        self.db.commit(); self.db.refresh(obj); return obj

    def map_points(self, user):
        return self.db.query(CommunityMapPoint).filter_by(organization_id=self.org(user), is_active=True).order_by(CommunityMapPoint.point_type, CommunityMapPoint.name).all()

    def create_map_point(self, user, data):
        self._require_admin(user)
        obj = CommunityMapPoint(organization_id=self.org(user), **data.model_dump())
        self.db.add(obj); self.db.commit(); self.db.refresh(obj); return obj

    def update_map_point(self, user, point_id, data):
        self._require_admin(user)
        obj = self.db.query(CommunityMapPoint).filter_by(id=point_id, organization_id=self.org(user)).first()
        if not obj: raise HTTPException(404, "Map point not found.")
        for key, value in data.model_dump(exclude_unset=True).items(): setattr(obj, key, value)
        self.db.commit(); self.db.refresh(obj); return obj
