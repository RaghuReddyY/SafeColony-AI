from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database.base_class import Base


class ServiceRequest(Base):
    __tablename__ = "service_requests"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    provider_id = Column(Integer, ForeignKey("community_services.id", ondelete="SET NULL"), nullable=True)
    vendor_id = Column(Integer, ForeignKey("marketplace_vendors.id", ondelete="SET NULL"), nullable=True, index=True)
    category = Column(String(60), nullable=False, index=True)
    title = Column(String(160), nullable=False)
    description = Column(Text, nullable=True)
    preferred_slot = Column(String(100), nullable=True)
    status = Column(String(30), nullable=False, default="REQUESTED")
    quoted_amount = Column(Numeric(12,2), nullable=True)
    payment_status = Column(String(20), nullable=False, default="PENDING")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    resident_user = relationship("User", foreign_keys=[resident_user_id])
    provider = relationship("CommunityService", foreign_keys=[provider_id])
    vendor = relationship("MarketplaceVendor", foreign_keys=[vendor_id])


class VendorOffer(Base):
    __tablename__ = "vendor_offers"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    vendor_id = Column(Integer, ForeignKey("marketplace_vendors.id", ondelete="CASCADE"), nullable=False, index=True)
    event_id = Column(Integer, ForeignKey("marketplace_events.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(160), nullable=False)
    description = Column(Text, nullable=True)
    discount_percent = Column(Numeric(5,2), nullable=False, default=0)
    min_orders = Column(Integer, nullable=False, default=1)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    vendor = relationship("MarketplaceVendor")
    event = relationship("MarketplaceEvent")


class VendorRating(Base):
    __tablename__ = "vendor_ratings"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    vendor_id = Column(Integer, ForeignKey("marketplace_vendors.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    order_id = Column(Integer, ForeignKey("marketplace_orders.id", ondelete="SET NULL"), nullable=True)
    rating = Column(Integer, nullable=False)
    quality = Column(Integer, nullable=True)
    price = Column(Integer, nullable=True)
    delivery = Column(Integer, nullable=True)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    vendor = relationship("MarketplaceVendor")
    resident_user = relationship("User", foreign_keys=[resident_user_id])


class CommunityParcel(Base):
    __tablename__ = "community_parcels"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    order_id = Column(Integer, ForeignKey("marketplace_orders.id", ondelete="CASCADE"), nullable=False, unique=True)
    apartment_label = Column(String(80), nullable=False)
    hub = Column(String(120), nullable=False, default="Main Gate")
    pickup_code = Column(String(20), nullable=False)
    status = Column(String(30), nullable=False, default="AT_HUB")
    handed_to_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    picked_up_at = Column(DateTime(timezone=True), nullable=True)
    handed_to_user = relationship("User", foreign_keys=[handed_to_user_id])


class UtilityProvider(Base):
    __tablename__ = "utility_providers"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(120), nullable=False)
    utility_type = Column(String(40), nullable=False, index=True)
    integration_type = Column(String(30), nullable=False, default="MANUAL")
    status = Column(String(20), nullable=False, default="ONBOARDING", index=True)
    contact_name = Column(String(100), nullable=True)
    contact_email = Column(String(120), nullable=True)
    contact_phone = Column(String(30), nullable=True)
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True, server_default="true")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())


class CommunityMapPoint(Base):
    __tablename__ = "community_map_points"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    point_type = Column(String(40), nullable=False, index=True)
    name = Column(String(120), nullable=False)
    description = Column(Text, nullable=True)
    address = Column(String(255), nullable=True)
    latitude = Column(Numeric(9, 6), nullable=False)
    longitude = Column(Numeric(9, 6), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True, server_default="true")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())


class UtilityBill(Base):
    __tablename__ = "utility_bills"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    utility_type = Column(String(40), nullable=False, index=True)
    provider_name = Column(String(120), nullable=False)
    account_reference = Column(String(120), nullable=True)
    amount = Column(Numeric(12,2), nullable=False)
    due_date = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(20), nullable=False, default="PENDING")
    payment_reference = Column(String(120), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())


class RecurringOrder(Base):
    __tablename__ = "recurring_orders"
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    vendor_id = Column(Integer, ForeignKey("marketplace_vendors.id", ondelete="SET NULL"), nullable=True, index=True)
    category = Column(String(60), nullable=False)
    description = Column(String(255), nullable=False)
    cadence = Column(String(40), nullable=False)
    preferred_day = Column(String(20), nullable=True)
    preferred_slot = Column(String(100), nullable=True)
    active = Column(Boolean, nullable=False, default=True)
    next_run_at = Column(DateTime(timezone=True), nullable=True, index=True)
    last_run_at = Column(DateTime(timezone=True), nullable=True)
    last_generated_order_id = Column(Integer, nullable=True)
    vendor = relationship("MarketplaceVendor", foreign_keys=[vendor_id])
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
