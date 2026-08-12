"""add organization and audit fields to security alerts

Revision ID: c4b7e5f1d2a9
Revises: aa21f7c8d901
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c4b7e5f1d2a9"
down_revision: Union[str, Sequence[str], None] = "aa21f7c8d901"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "security_alerts",
        sa.Column("organization_id", sa.Integer(), nullable=True),
    )
    op.add_column(
        "security_alerts",
        sa.Column("raised_by_user_id", sa.Integer(), nullable=True),
    )
    op.add_column(
        "security_alerts",
        sa.Column("source_role", sa.String(length=30), nullable=True),
    )
    op.add_column(
        "security_alerts",
        sa.Column("resolved_by_user_id", sa.Integer(), nullable=True),
    )
    op.add_column(
        "security_alerts",
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
    )

    op.create_foreign_key(
        "fk_security_alerts_organization",
        "security_alerts",
        "organizations",
        ["organization_id"],
        ["id"],
    )
    op.create_foreign_key(
        "fk_security_alerts_raised_by_user",
        "security_alerts",
        "users",
        ["raised_by_user_id"],
        ["id"],
    )
    op.create_foreign_key(
        "fk_security_alerts_resolved_by_user",
        "security_alerts",
        "users",
        ["resolved_by_user_id"],
        ["id"],
    )

    op.create_index(
        "ix_security_alerts_organization_id",
        "security_alerts",
        ["organization_id"],
    )
    op.create_index(
        "ix_security_alerts_raised_by_user_id",
        "security_alerts",
        ["raised_by_user_id"],
    )

    # Backfill existing resident-originated alerts so they remain visible in
    # the correct organization's security dashboard.
    op.execute(
        """
        UPDATE security_alerts AS sa
        SET organization_id = u.organization_id,
            raised_by_user_id = r.user_id,
            source_role = 'RESIDENT'
        FROM residents AS r
        JOIN users AS u ON u.id = r.user_id
        WHERE sa.resident_id = r.id
          AND sa.organization_id IS NULL
        """
    )


def downgrade() -> None:
    op.drop_index("ix_security_alerts_raised_by_user_id", table_name="security_alerts")
    op.drop_index("ix_security_alerts_organization_id", table_name="security_alerts")
    op.drop_constraint(
        "fk_security_alerts_resolved_by_user",
        "security_alerts",
        type_="foreignkey",
    )
    op.drop_constraint(
        "fk_security_alerts_raised_by_user",
        "security_alerts",
        type_="foreignkey",
    )
    op.drop_constraint(
        "fk_security_alerts_organization",
        "security_alerts",
        type_="foreignkey",
    )
    op.drop_column("security_alerts", "resolved_at")
    op.drop_column("security_alerts", "resolved_by_user_id")
    op.drop_column("security_alerts", "source_role")
    op.drop_column("security_alerts", "raised_by_user_id")
    op.drop_column("security_alerts", "organization_id")
