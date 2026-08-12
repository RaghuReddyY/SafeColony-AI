"""add payment configuration and direct UPI verification

Revision ID: aa21f7c8d901
Revises: 9d5f2a1c7e40
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "aa21f7c8d901"
down_revision: Union[str, Sequence[str], None] = "9d5f2a1c7e40"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "organizations",
        sa.Column(
            "payment_mode",
            sa.String(length=20),
            nullable=False,
            server_default="RAZORPAY",
        ),
    )
    op.add_column(
        "organizations",
        sa.Column(
            "payment_upi_id",
            sa.String(length=120),
            nullable=True,
        ),
    )
    op.add_column(
        "organizations",
        sa.Column(
            "payment_display_name",
            sa.String(length=150),
            nullable=True,
        ),
    )
    op.add_column(
        "organizations",
        sa.Column(
            "payment_phone",
            sa.String(length=20),
            nullable=True,
        ),
    )

    op.add_column(
        "maintenance_payments",
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default="VERIFIED",
        ),
    )
    op.add_column(
        "maintenance_payments",
        sa.Column(
            "verified_at",
            sa.DateTime(),
            nullable=True,
        ),
    )
    op.add_column(
        "maintenance_payments",
        sa.Column(
            "verified_by",
            sa.Integer(),
            nullable=True,
        ),
    )
    op.create_foreign_key(
        "fk_maintenance_payments_verified_by_users",
        "maintenance_payments",
        "users",
        ["verified_by"],
        ["id"],
    )
    op.create_index(
        "ix_maintenance_payments_status",
        "maintenance_payments",
        ["status"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_maintenance_payments_status",
        table_name="maintenance_payments",
    )
    op.drop_constraint(
        "fk_maintenance_payments_verified_by_users",
        "maintenance_payments",
        type_="foreignkey",
    )
    op.drop_column("maintenance_payments", "verified_by")
    op.drop_column("maintenance_payments", "verified_at")
    op.drop_column("maintenance_payments", "status")

    op.drop_column("organizations", "payment_phone")
    op.drop_column("organizations", "payment_display_name")
    op.drop_column("organizations", "payment_upi_id")
    op.drop_column("organizations", "payment_mode")
