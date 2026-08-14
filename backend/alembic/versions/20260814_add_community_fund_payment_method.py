"""add payment settings to community funds

Revision ID: 20260814_fundpay
Revises: 20260814_funds
"""
from alembic import op
import sqlalchemy as sa

revision = "20260814_fundpay"
down_revision = "20260814_funds"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("community_funds", sa.Column("payment_method", sa.String(30), nullable=False, server_default="MANUAL"))
    op.add_column("community_funds", sa.Column("payment_upi_id", sa.String(120), nullable=True))
    op.add_column("community_funds", sa.Column("payment_display_name", sa.String(150), nullable=True))

def downgrade():
    op.drop_column("community_funds", "payment_display_name")
    op.drop_column("community_funds", "payment_upi_id")
    op.drop_column("community_funds", "payment_method")
