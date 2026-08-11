"""add maintenance money management

Revision ID: 9d5f2a1c7e40
Revises: f5f29adfe386
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "9d5f2a1c7e40"
down_revision: Union[str, Sequence[str], None] = "f5f29adfe386"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "maintenance_periods",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), nullable=False),
        sa.Column("month", sa.Date(), nullable=False),
        sa.Column("monthly_amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("opening_balance", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["organization_id"], ["organizations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.UniqueConstraint("organization_id", "month", name="uq_maintenance_period_org_month"),
    )
    op.create_index("ix_maintenance_periods_organization_id", "maintenance_periods", ["organization_id"])
    op.create_index("ix_maintenance_periods_month", "maintenance_periods", ["month"])

    op.create_table(
        "maintenance_bills",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("period_id", sa.Integer(), nullable=False),
        sa.Column("resident_id", sa.Integer(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("carried_forward", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("late_fee", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("total_due", sa.Numeric(12, 2), nullable=False),
        sa.Column("amount_paid", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="UNPAID"),
        sa.Column("paid_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["period_id"], ["maintenance_periods.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["resident_id"], ["residents.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("period_id", "resident_id", name="uq_maintenance_bill_period_resident"),
    )
    op.create_index("ix_maintenance_bills_period_id", "maintenance_bills", ["period_id"])
    op.create_index("ix_maintenance_bills_resident_id", "maintenance_bills", ["resident_id"])
    op.create_index("ix_maintenance_bills_status", "maintenance_bills", ["status"])

    op.create_table(
        "maintenance_payments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("bill_id", sa.Integer(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("payment_method", sa.String(30), nullable=False),
        sa.Column("reference", sa.String(100), nullable=True),
        sa.Column("paid_at", sa.DateTime(), nullable=False),
        sa.Column("recorded_by", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["bill_id"], ["maintenance_bills.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["recorded_by"], ["users.id"]),
    )
    op.create_index("ix_maintenance_payments_bill_id", "maintenance_payments", ["bill_id"])

    op.create_table(
        "maintenance_expenses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("period_id", sa.Integer(), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("spent_on", sa.Date(), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["period_id"], ["maintenance_periods.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
    )
    op.create_index("ix_maintenance_expenses_period_id", "maintenance_expenses", ["period_id"])


def downgrade() -> None:
    op.drop_table("maintenance_expenses")
    op.drop_table("maintenance_payments")
    op.drop_table("maintenance_bills")
    op.drop_table("maintenance_periods")
