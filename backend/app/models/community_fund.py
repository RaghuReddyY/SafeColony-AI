from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class CommunityFund(Base):
    __tablename__ = "community_funds"

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    purpose: Mapped[str] = mapped_column(Text, nullable=False)
    target_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    # FIXED: resident must pay exactly per_unit_amount.
    # SUGGESTED: per_unit_amount is the suggested contribution, but resident may pay any amount.
    # FREE: resident may contribute any positive amount.
    contribution_mode: Mapped[str] = mapped_column(String(20), default="FREE", nullable=False)
    per_unit_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    payment_method: Mapped[str] = mapped_column(String(30), default="MANUAL", nullable=False)
    payment_upi_id: Mapped[str | None] = mapped_column(String(120), nullable=True)
    payment_display_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="DRAFT", nullable=False, index=True)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    contributions = relationship("CommunityFundContribution", back_populates="fund", cascade="all, delete-orphan")
    expenses = relationship("CommunityFundExpense", back_populates="fund", cascade="all, delete-orphan")


class CommunityFundContribution(Base):
    __tablename__ = "community_fund_contributions"

    id: Mapped[int] = mapped_column(primary_key=True)
    fund_id: Mapped[int] = mapped_column(ForeignKey("community_funds.id", ondelete="CASCADE"), nullable=False, index=True)
    resident_id: Mapped[int | None] = mapped_column(ForeignKey("residents.id", ondelete="SET NULL"), nullable=True, index=True)
    payer_name: Mapped[str] = mapped_column(String(120), nullable=False)
    block_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    unit_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    payment_method: Mapped[str] = mapped_column(String(30), default="MANUAL", nullable=False)
    reference: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="VERIFIED", nullable=False, index=True)
    collected_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    verified_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    recorded_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    fund = relationship("CommunityFund", back_populates="contributions")


class CommunityFundExpense(Base):
    __tablename__ = "community_fund_expenses"

    id: Mapped[int] = mapped_column(primary_key=True)
    fund_id: Mapped[int] = mapped_column(ForeignKey("community_funds.id", ondelete="CASCADE"), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(60), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    spent_on: Mapped[date] = mapped_column(Date, nullable=False)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    fund = relationship("CommunityFund", back_populates="expenses")
