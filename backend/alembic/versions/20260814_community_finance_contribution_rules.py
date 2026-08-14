"""add community contribution rules and payment tracking

Revision ID: 20260814_cf_rules
Revises: 20260814_fundpay
"""
from alembic import op
import sqlalchemy as sa

revision = "20260814_cf_rules"
down_revision = "20260814_fundpay"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("community_funds", sa.Column("contribution_mode", sa.String(20), nullable=False, server_default="FREE"))
    op.add_column("community_funds", sa.Column("per_unit_amount", sa.Numeric(12, 2), nullable=True))
    op.add_column("community_fund_contributions", sa.Column("unit_number", sa.String(50), nullable=True))
    op.add_column("community_fund_contributions", sa.Column("status", sa.String(20), nullable=False, server_default="VERIFIED"))
    op.add_column("community_fund_contributions", sa.Column("verified_at", sa.DateTime(), nullable=True))
    op.add_column("community_fund_contributions", sa.Column("verified_by", sa.Integer(), nullable=True))
    op.create_index("ix_community_fund_contributions_status", "community_fund_contributions", ["status"])
    op.create_foreign_key("fk_cf_contribution_verified_by", "community_fund_contributions", "users", ["verified_by"], ["id"])


def downgrade():
    op.drop_constraint("fk_cf_contribution_verified_by", "community_fund_contributions", type_="foreignkey")
    op.drop_index("ix_community_fund_contributions_status", table_name="community_fund_contributions")
    op.drop_column("community_fund_contributions", "verified_by")
    op.drop_column("community_fund_contributions", "verified_at")
    op.drop_column("community_fund_contributions", "status")
    op.drop_column("community_fund_contributions", "unit_number")
    op.drop_column("community_funds", "per_unit_amount")
    op.drop_column("community_funds", "contribution_mode")
