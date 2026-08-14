"""add organization-wide community funds

Revision ID: 20260814_funds
Revises: f6a7b8c9d0e1
"""
from alembic import op
import sqlalchemy as sa

revision = "20260814_funds"
down_revision = "f6a7b8c9d0e1"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "community_funds",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=False),
        sa.Column("target_amount", sa.Numeric(12, 2), nullable=True),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="OPEN"),
        sa.Column("created_by", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["organization_id"], ["organizations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
    )
    op.create_index("ix_community_funds_organization_id", "community_funds", ["organization_id"])
    op.create_index("ix_community_funds_status", "community_funds", ["status"])

    op.create_table(
        "community_fund_contributions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("fund_id", sa.Integer(), nullable=False),
        sa.Column("resident_id", sa.Integer(), nullable=True),
        sa.Column("payer_name", sa.String(120), nullable=False),
        sa.Column("block_name", sa.String(100), nullable=True),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("payment_method", sa.String(30), nullable=False),
        sa.Column("reference", sa.String(100), nullable=True),
        sa.Column("collected_at", sa.DateTime(), nullable=False),
        sa.Column("recorded_by", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["fund_id"], ["community_funds.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["resident_id"], ["residents.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["recorded_by"], ["users.id"]),
    )
    op.create_index("ix_community_fund_contributions_fund_id", "community_fund_contributions", ["fund_id"])
    op.create_index("ix_community_fund_contributions_resident_id", "community_fund_contributions", ["resident_id"])

    op.create_table(
        "community_fund_expenses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("fund_id", sa.Integer(), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("spent_on", sa.Date(), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["fund_id"], ["community_funds.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
    )
    op.create_index("ix_community_fund_expenses_fund_id", "community_fund_expenses", ["fund_id"])


def downgrade():
    op.drop_table("community_fund_expenses")
    op.drop_table("community_fund_contributions")
    op.drop_table("community_funds")
