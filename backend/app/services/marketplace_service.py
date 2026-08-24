from collections import defaultdict
from decimal import Decimal
from datetime import datetime, timezone
import secrets

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func

from app.models.marketplace import MarketplaceVendor, MarketplaceEvent, MarketplaceOrder, MarketplaceOrderItem
from app.models.super_app import VendorOffer, VendorRating, CommunityParcel
from app.models.resident import Resident
from app.models.user import User
from app.models.notification import Notification
from app.enums import UserRole
from app.auth.hashing import hash_password


ADMIN_ROLES = {
    UserRole.SYSTEM_ADMIN.value,
    UserRole.ORGANIZATION_ADMIN.value,
    UserRole.BLOCK_ADMIN.value,
    UserRole.COMMUNITY_FINANCE_ADMIN.value,
}


class MarketplaceService:
    def __init__(self, db: Session):
        self.db = db

    def _org(self, user: User) -> int:
        if user.organization_id is None:
            raise HTTPException(status_code=400, detail="User is not associated with an organization.")
        return user.organization_id

    def list_vendors(self, user: User):
        org = self._org(user)
        return self.db.query(MarketplaceVendor).filter(
            MarketplaceVendor.organization_id == org,
            MarketplaceVendor.is_active.is_(True),
        ).order_by(MarketplaceVendor.name.asc()).all()

    def create_vendor_account(self, user: User, data):
        org = self._org(user)
        email = data.email.strip().lower()
        phone = data.phone.strip() if data.phone else None
        if self.db.query(User).filter(func.lower(User.email) == email).first():
            raise HTTPException(status_code=409, detail="Email already exists.")
        if phone and self.db.query(User).filter(User.phone == phone).first():
            raise HTTPException(status_code=409, detail="Phone already exists.")
        user_obj = User(full_name=data.full_name.strip(), email=email, phone=phone or f"vendor-{secrets.token_hex(6)}",
                        password_hash=hash_password(data.password), role=UserRole.VENDOR.value,
                        status="ACTIVE", is_active=True, organization_id=org)
        self.db.add(user_obj)
        self.db.flush()
        vendor = MarketplaceVendor(organization_id=org, user_id=user_obj.id, name=data.name.strip(),
                                  category=data.category.strip().upper(), phone=phone,
                                  notes=data.notes.strip() if data.notes else None)
        self.db.add(vendor)
        self.db.commit()
        self.db.refresh(vendor)
        return {**{c.name:getattr(vendor,c.name) for c in MarketplaceVendor.__table__.columns},
                "email": user_obj.email, "user_full_name": user_obj.full_name, "user_active": user_obj.is_active}

    def create_vendor(self, user: User, data):
        org = self._org(user)
        if data.user_id:
            linked = self.db.query(User).filter(
                User.id == data.user_id,
                User.organization_id == org,
            ).first()
            if not linked:
                raise HTTPException(status_code=404, detail="Vendor user not found in this organization.")
        item = MarketplaceVendor(
            organization_id=org,
            user_id=data.user_id,
            name=data.name.strip(),
            category=data.category.strip().upper(),
            phone=data.phone.strip() if data.phone else None,
            notes=data.notes.strip() if data.notes else None,
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def list_events(self, user: User, include_closed: bool = False):
        org = self._org(user)
        q = self.db.query(MarketplaceEvent).options(joinedload(MarketplaceEvent.vendor)).filter(
            MarketplaceEvent.organization_id == org,
            MarketplaceEvent.is_active.is_(True),
        )
        if not include_closed:
            q = q.filter(MarketplaceEvent.status.in_(["OPEN", "CLOSED"]))
        events = q.order_by(MarketplaceEvent.scheduled_for.asc().nullslast(), MarketplaceEvent.id.desc()).all()
        return [self._event_response(e) for e in events]

    def create_event(self, user: User, data):
        org = self._org(user)
        vendor = None
        if data.vendor_id:
            vendor = self.db.query(MarketplaceVendor).filter(
                MarketplaceVendor.id == data.vendor_id,
                MarketplaceVendor.organization_id == org,
                MarketplaceVendor.is_active.is_(True),
            ).first()
            if not vendor:
                raise HTTPException(status_code=404, detail="Vendor not found.")
        item = MarketplaceEvent(
            organization_id=org,
            vendor_id=vendor.id if vendor else None,
            created_by_id=user.id,
            title=data.title.strip(),
            category=data.category.strip().upper(),
            event_type=data.event_type,
            description=data.description.strip() if data.description else None,
            cutoff_at=data.cutoff_at,
            scheduled_for=data.scheduled_for,
            delivery_mode=data.delivery_mode,
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return self._event_response(item)

    def _event_response(self, e: MarketplaceEvent):
        order_count = self.db.query(MarketplaceOrder).filter(MarketplaceOrder.event_id == e.id).count()
        apartment_count = self.db.query(MarketplaceOrder.resident_user_id).filter(
            MarketplaceOrder.event_id == e.id
        ).distinct().count()
        return {
            "id": e.id,
            "title": e.title,
            "category": e.category,
            "event_type": e.event_type,
            "description": e.description,
            "vendor_id": e.vendor_id,
            "vendor_name": e.vendor.name if e.vendor else None,
            "cutoff_at": e.cutoff_at,
            "scheduled_for": e.scheduled_for,
            "delivery_mode": e.delivery_mode,
            "status": e.status,
            "order_count": order_count,
            "apartment_count": apartment_count,
        }

    def place_order(self, user: User, event_id: int, data):
        org = self._org(user)
        event = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.id == event_id,
            MarketplaceEvent.organization_id == org,
            MarketplaceEvent.is_active.is_(True),
        ).first()
        if not event:
            raise HTTPException(status_code=404, detail="Community event not found.")
        if event.status != "OPEN":
            raise HTTPException(status_code=400, detail="This community event is not accepting orders.")
        if event.cutoff_at is not None:
            cutoff = event.cutoff_at
            if cutoff.tzinfo is None:
                cutoff = cutoff.replace(tzinfo=timezone.utc)
            if datetime.now(timezone.utc) >= cutoff:
                event.status = "CLOSED"
                self.db.commit()
                raise HTTPException(status_code=400, detail="The order cutoff for this community event has passed.")
        existing = self.db.query(MarketplaceOrder).filter(
            MarketplaceOrder.event_id == event.id,
            MarketplaceOrder.resident_user_id == user.id,
            MarketplaceOrder.status.notin_(["CANCELLED"]),
        ).first()
        if existing:
            raise HTTPException(status_code=409, detail="You already have an order for this community event.")

        total = sum((Decimal(str(i.unit_price)) * Decimal(str(i.quantity)) for i in data.items), Decimal("0"))
        order = MarketplaceOrder(
            event_id=event.id,
            organization_id=org,
            resident_user_id=user.id,
            delivery_mode=data.delivery_mode,
            total_amount=total,
            notes=data.notes,
            service_slot=data.service_slot,
            payment_reference=data.payment_reference,
        )
        self.db.add(order)
        self.db.flush()
        for item in data.items:
            self.db.add(MarketplaceOrderItem(
                order_id=order.id,
                name=item.name.strip(),
                quantity=item.quantity,
                unit=item.unit.strip(),
                unit_price=item.unit_price,
            ))
        if event.vendor and event.vendor.user_id:
            self.db.add(Notification(
                user_id=event.vendor.user_id,
                title="New community marketplace order",
                message=f"A new resident order was placed for {event.title}. Open Vendor Portal to review the order and consolidated demand.",
                notification_type="MARKETPLACE",
            ))
        self.db.commit()
        self.db.refresh(order)
        return self._order_response(order)

    def my_orders(self, user: User):
        org = self._org(user)
        orders = self.db.query(MarketplaceOrder).options(
            joinedload(MarketplaceOrder.event),
            joinedload(MarketplaceOrder.items),
            joinedload(MarketplaceOrder.resident_user),
        ).filter(
            MarketplaceOrder.organization_id == org,
            MarketplaceOrder.resident_user_id == user.id,
        ).order_by(MarketplaceOrder.created_at.desc()).all()
        return [self._order_response(o) for o in orders]

    def _vendor_for_user(self, user: User):
        org = self._org(user)
        vendor = self.db.query(MarketplaceVendor).filter(
            MarketplaceVendor.organization_id == org,
            MarketplaceVendor.user_id == user.id,
            MarketplaceVendor.is_active.is_(True),
        ).first()
        if not vendor:
            raise HTTPException(status_code=403, detail="Your account is not linked to a SafeColony vendor.")
        return org, vendor

    def vendor_dashboard(self, user: User):
        org, vendor = self._vendor_for_user(user)
        events = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.organization_id == org, MarketplaceEvent.vendor_id == vendor.id, MarketplaceEvent.is_active.is_(True)
        ).all()
        orders = self.db.query(MarketplaceOrder).join(MarketplaceEvent).filter(
            MarketplaceOrder.organization_id == org, MarketplaceEvent.vendor_id == vendor.id
        ).all()
        total = sum((Decimal(str(o.total_amount)) for o in orders), Decimal("0"))
        now = datetime.now(timezone.utc)
        upcoming = sum(1 for e in events if e.scheduled_for and (e.scheduled_for.replace(tzinfo=timezone.utc) if e.scheduled_for.tzinfo is None else e.scheduled_for) >= now)
        return {
            "vendor_id": vendor.id, "vendor_name": vendor.name, "category": vendor.category, "phone": vendor.phone, "active": vendor.is_active,
            "open_events": sum(1 for e in events if e.status == "OPEN"), "upcoming_events": upcoming,
            "total_orders": len(orders), "pending_orders": sum(1 for o in orders if o.status in {"PLACED", "ACCEPTED", "PREPARING"}),
            "ready_orders": sum(1 for o in orders if o.status == "READY"), "delivered_orders": sum(1 for o in orders if o.status == "DELIVERED"),
            "total_sales": total,
            "average_rating": float(self.db.query(func.avg(VendorRating.rating)).filter(VendorRating.vendor_id == vendor.id).scalar() or 0),
            "rating_count": self.db.query(VendorRating).filter(VendorRating.vendor_id == vendor.id).count(),
        }

    def vendor_events(self, user: User):
        org, vendor = self._vendor_for_user(user)
        events = self.db.query(MarketplaceEvent).options(joinedload(MarketplaceEvent.vendor)).filter(
            MarketplaceEvent.organization_id == org, MarketplaceEvent.vendor_id == vendor.id, MarketplaceEvent.is_active.is_(True)
        ).order_by(MarketplaceEvent.scheduled_for.asc().nullslast(), MarketplaceEvent.id.desc()).all()
        out=[]
        for e in events:
            r=self._event_response(e)
            r["total_amount"] = sum((Decimal(str(o.total_amount)) for o in e.orders if o.status != "CANCELLED"), Decimal("0"))
            out.append(r)
        return out

    def vendor_aggregate(self, user: User, event_id: int):
        org, vendor = self._vendor_for_user(user)
        event = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.id == event_id, MarketplaceEvent.organization_id == org, MarketplaceEvent.vendor_id == vendor.id
        ).first()
        if not event:
            raise HTTPException(status_code=404, detail="Vendor event not found.")
        return self.aggregate(user, event_id)

    def update_vendor_event_status(self, user: User, event_id: int, new_status: str):
        org, vendor = self._vendor_for_user(user)
        event = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.id == event_id, MarketplaceEvent.organization_id == org, MarketplaceEvent.vendor_id == vendor.id
        ).first()
        if not event:
            raise HTTPException(status_code=404, detail="Vendor event not found.")
        if new_status not in {"OPEN", "CLOSED", "COMPLETED", "CANCELLED"}:
            raise HTTPException(status_code=400, detail="Invalid event status.")
        event.status = new_status
        self.db.commit(); self.db.refresh(event)
        return self._event_response(event) | {"total_amount": sum((Decimal(str(o.total_amount)) for o in event.orders if o.status != "CANCELLED"), Decimal("0"))}

    def update_vendor_profile(self, user: User, data):
        _, vendor = self._vendor_for_user(user)
        vendor.name = data.name.strip(); vendor.category = data.category.strip().upper()
        vendor.phone = data.phone.strip() if data.phone else None
        vendor.notes = data.notes.strip() if data.notes else None
        self.db.commit(); self.db.refresh(vendor)
        return vendor

    def vendor_offers(self, user: User):
        org, vendor = self._vendor_for_user(user)
        return self.db.query(VendorOffer).filter(
            VendorOffer.organization_id == org, VendorOffer.vendor_id == vendor.id, VendorOffer.is_active.is_(True)
        ).order_by(VendorOffer.created_at.desc()).all()

    def create_vendor_offer(self, user: User, data):
        org, vendor = self._vendor_for_user(user)
        if data.event_id is not None:
            event = self.db.query(MarketplaceEvent).filter(
                MarketplaceEvent.id == data.event_id, MarketplaceEvent.organization_id == org, MarketplaceEvent.vendor_id == vendor.id
            ).first()
            if not event:
                raise HTTPException(status_code=404, detail="Community day not found for this vendor.")
        obj = VendorOffer(organization_id=org, vendor_id=vendor.id, **data.model_dump())
        self.db.add(obj); self.db.commit(); self.db.refresh(obj)
        return obj

    def vendor_orders(self, user: User):
        org = self._org(user)
        vendor = self.db.query(MarketplaceVendor).filter(
            MarketplaceVendor.organization_id == org,
            MarketplaceVendor.user_id == user.id,
            MarketplaceVendor.is_active.is_(True),
        ).first()
        if not vendor:
            raise HTTPException(status_code=403, detail="Your account is not linked to a SafeColony vendor.")
        orders = self.db.query(MarketplaceOrder).options(
            joinedload(MarketplaceOrder.event),
            joinedload(MarketplaceOrder.items),
            joinedload(MarketplaceOrder.resident_user),
        ).join(MarketplaceEvent, MarketplaceOrder.event_id == MarketplaceEvent.id).filter(
            MarketplaceOrder.organization_id == org,
            MarketplaceEvent.vendor_id == vendor.id,
        ).order_by(MarketplaceOrder.created_at.desc()).all()
        return [self._order_response(o) for o in orders]

    def update_vendor_order(self, user: User, order_id: int, new_status: str):
        org = self._org(user)
        vendor = self.db.query(MarketplaceVendor).filter(
            MarketplaceVendor.organization_id == org,
            MarketplaceVendor.user_id == user.id,
            MarketplaceVendor.is_active.is_(True),
        ).first()
        if not vendor:
            raise HTTPException(status_code=403, detail="Vendor account is not linked.")
        order = self.db.query(MarketplaceOrder).join(MarketplaceEvent).filter(
            MarketplaceOrder.id == order_id,
            MarketplaceOrder.organization_id == org,
            MarketplaceEvent.vendor_id == vendor.id,
        ).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found.")
        allowed = {"ACCEPTED", "PREPARING", "READY", "DELIVERED", "CANCELLED"}
        if new_status not in allowed:
            raise HTTPException(status_code=400, detail="Invalid order status.")
        order.status = new_status
        if new_status == "DELIVERED":
            # A community-drop order becomes a parcel at the Main Gate once the
            # vendor marks it delivered. The unique order_id constraint plus the
            # lookup below make this idempotent for retries.
            parcel = self.db.query(CommunityParcel).filter_by(order_id=order.id).first()
            if parcel is None and order.delivery_mode == "COMMUNITY_DROP":
                resident = self.db.query(Resident).filter(
                    Resident.user_id == order.resident_user_id,
                    Resident.is_active.is_(True),
                ).first()
                apartment_label = None
                if resident and resident.unit:
                    section_name = resident.unit.section.name if resident.unit.section else None
                    apartment_label = f"{section_name} / {resident.unit.unit_number}" if section_name else resident.unit.unit_number
                if not apartment_label:
                    apartment_label = "Community Resident"
                parcel = CommunityParcel(
                    organization_id=org,
                    order_id=order.id,
                    apartment_label=apartment_label,
                    hub="Main Gate",
                    pickup_code=secrets.token_hex(3).upper(),
                    status="AT_HUB",
                )
                self.db.add(parcel)
                self.db.add(Notification(
                    user_id=order.resident_user_id,
                    title="Parcel ready at Main Gate",
                    message=f"Your {order.event.title} order has arrived at the Main Gate Delivery Hub. Pickup code: {parcel.pickup_code}.",
                    notification_type="DELIVERY_HUB",
                ))
        self.db.commit()
        self.db.refresh(order)
        return self._order_response(order)

    def aggregate(self, user: User, event_id: int):
        org = self._org(user)
        event = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.id == event_id,
            MarketplaceEvent.organization_id == org,
        ).first()
        if not event:
            raise HTTPException(status_code=404, detail="Community event not found.")
        orders = self.db.query(MarketplaceOrder).options(
            joinedload(MarketplaceOrder.items)
        ).filter(
            MarketplaceOrder.event_id == event_id,
            MarketplaceOrder.status != "CANCELLED",
        ).all()
        groups = defaultdict(lambda: {"quantity": Decimal("0"), "unit": "", "order_count": 0})
        for order in orders:
            seen = set()
            for item in order.items:
                key = (item.name.strip().lower(), item.unit)
                groups[key]["quantity"] += Decimal(str(item.quantity))
                groups[key]["unit"] = item.unit
                if key not in seen:
                    groups[key]["order_count"] += 1
                    seen.add(key)
        items = [
            {"name": key[0].title(), "quantity": value["quantity"], "unit": value["unit"], "order_count": value["order_count"]}
            for key, value in sorted(groups.items())
        ]
        return {
            "event_id": event.id,
            "event_title": event.title,
            "apartment_count": len({o.resident_user_id for o in orders}),
            "order_count": len(orders),
            "total_amount": sum((Decimal(str(o.total_amount)) for o in orders), Decimal("0")),
            "items": items,
        }

    def _order_response(self, o: MarketplaceOrder):
        return {
            "id": o.id,
            "event_id": o.event_id,
            "event_title": o.event.title if o.event else "",
            "resident_name": o.resident_user.full_name if o.resident_user else "Resident",
            "status": o.status,
            "payment_status": o.payment_status,
            "delivery_mode": o.delivery_mode,
            "total_amount": o.total_amount,
            "notes": o.notes,
            "service_slot": o.service_slot,
            "payment_reference": o.payment_reference,
            "items": [
                {
                    "name": i.name,
                    "quantity": i.quantity,
                    "unit": i.unit,
                    "unit_price": i.unit_price,
                } for i in o.items
            ],
        }


    def admin_orders(self, user: User, event_id: int | None = None):
        org = self._org(user)
        q = self.db.query(MarketplaceOrder).options(
            joinedload(MarketplaceOrder.event),
            joinedload(MarketplaceOrder.items),
            joinedload(MarketplaceOrder.resident_user),
        ).filter(MarketplaceOrder.organization_id == org)
        if event_id is not None:
            q = q.filter(MarketplaceOrder.event_id == event_id)
        orders = q.order_by(MarketplaceOrder.created_at.desc()).all()
        return [self._order_response(o) for o in orders]

    def update_event_status(self, user: User, event_id: int, status: str):
        org = self._org(user)
        event = self.db.query(MarketplaceEvent).filter(
            MarketplaceEvent.id == event_id,
            MarketplaceEvent.organization_id == org,
        ).first()
        if not event:
            raise HTTPException(status_code=404, detail="Community event not found.")
        event.status = status
        self.db.commit()
        self.db.refresh(event)
        return self._event_response(event)
