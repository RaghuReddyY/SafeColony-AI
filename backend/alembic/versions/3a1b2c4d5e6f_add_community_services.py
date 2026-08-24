"""add organization community services directory"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "3a1b2c4d5e6f"
down_revision: Union[str, Sequence[str], None] = "20260814_cflife"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "community_services",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), nullable=False),
        sa.Column("created_by_id", sa.Integer(), nullable=True),
        sa.Column("updated_by_id", sa.Integer(), nullable=True),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("category", sa.String(length=80), nullable=False),
        sa.Column("phone", sa.String(length=30), nullable=False),
        sa.Column("work_description", sa.String(length=255), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["organization_id"], ["organizations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["updated_by_id"], ["users.id"], ondelete="SET NULL"),
    )
    op.create_index("ix_community_services_organization_id", "community_services", ["organization_id"])
    op.create_index("ix_community_services_category", "community_services", ["category"])


def downgrade() -> None:
    op.drop_index("ix_community_services_category", table_name="community_services")
    op.drop_index("ix_community_services_organization_id", table_name="community_services")
    op.drop_table("community_services")
