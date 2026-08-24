from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database.base_class import Base


class MarketplaceVendor(Base):
    __tablename__ = "marketplace_vendors"

    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, unique=True)
    name = Column(String(120), nullable=False)
    category = Column(String(60), nullable=False, index=True)
    phone = Column(String(30), nullable=True)
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True, server_default="true")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])


class MarketplaceEvent(Base):
    __tablename__ = "marketplace_events"

    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    vendor_id = Column(Integer, ForeignKey("marketplace_vendors.id", ondelete="SET NULL"), nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    title = Column(String(160), nullable=False)
    category = Column(String(60), nullable=False, index=True)
    event_type = Column(String(20), nullable=False, default="PRODUCT")
    description = Column(Text, nullable=True)
    cutoff_at = Column(DateTime(timezone=True), nullable=True)
    scheduled_for = Column(DateTime(timezone=True), nullable=True)
    delivery_mode = Column(String(30), nullable=False, default="COMMUNITY_DROP")
    status = Column(String(20), nullable=False, default="OPEN")
    is_active = Column(Boolean, nullable=False, default=True)

    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    vendor = relationship("MarketplaceVendor")
    created_by = relationship("User", foreign_keys=[created_by_id])
    orders = relationship("MarketplaceOrder", back_populates="event", cascade="all, delete-orphan")


class MarketplaceOrder(Base):
    __tablename__ = "marketplace_orders"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("marketplace_events.id", ondelete="CASCADE"), nullable=False, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    status = Column(String(20), nullable=False, default="PLACED")
    payment_status = Column(String(20), nullable=False, default="PENDING")
    delivery_mode = Column(String(30), nullable=False, default="COMMUNITY_DROP")
    total_amount = Column(Numeric(12, 2), nullable=False, default=0)
    notes = Column(Text, nullable=True)
    service_slot = Column(String(80), nullable=True)
    payment_reference = Column(String(120), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    event = relationship("MarketplaceEvent", back_populates="orders")
    resident_user = relationship("User", foreign_keys=[resident_user_id])
    items = relationship("MarketplaceOrderItem", back_populates="order", cascade="all, delete-orphan")


class MarketplaceOrderItem(Base):
    __tablename__ = "marketplace_order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("marketplace_orders.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(160), nullable=False)
    quantity = Column(Numeric(12, 3), nullable=False)
    unit = Column(String(30), nullable=False, default="unit")
    unit_price = Column(Numeric(12, 2), nullable=False, default=0)

    order = relationship("MarketplaceOrder", back_populates="items")
