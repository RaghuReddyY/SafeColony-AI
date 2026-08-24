"""add password reset, utility providers and community map points

Revision ID: 20260824_super_app_gaps
Revises: 20260821_vendor_service_requests
"""
from alembic import op
import sqlalchemy as sa

revision = "20260824_super_app_gaps"
down_revision = "20260821_vendor_service_requests"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "password_reset_tokens",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("used_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("ix_password_reset_tokens_user_id", "password_reset_tokens", ["user_id"])
    op.create_index("ix_password_reset_tokens_token_hash", "password_reset_tokens", ["token_hash"], unique=True)
    op.create_index("ix_password_reset_user_expires", "password_reset_tokens", ["user_id", "expires_at"])

    op.create_table(
        "utility_providers",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("utility_type", sa.String(length=40), nullable=False),
        sa.Column("integration_type", sa.String(length=30), nullable=False, server_default="MANUAL"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="ONBOARDING"),
        sa.Column("contact_name", sa.String(length=100), nullable=True),
        sa.Column("contact_email", sa.String(length=120), nullable=True),
        sa.Column("contact_phone", sa.String(length=30), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("ix_utility_providers_organization_id", "utility_providers", ["organization_id"])
    op.create_index("ix_utility_providers_utility_type", "utility_providers", ["utility_type"])
    op.create_index("ix_utility_providers_status", "utility_providers", ["status"])

    op.create_table(
        "community_map_points",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("organization_id", sa.Integer(), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("point_type", sa.String(length=40), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("address", sa.String(length=255), nullable=True),
        sa.Column("latitude", sa.Numeric(9, 6), nullable=False),
        sa.Column("longitude", sa.Numeric(9, 6), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("ix_community_map_points_organization_id", "community_map_points", ["organization_id"])
    op.create_index("ix_community_map_points_point_type", "community_map_points", ["point_type"])


def downgrade():
    op.drop_index("ix_community_map_points_point_type", table_name="community_map_points")
    op.drop_index("ix_community_map_points_organization_id", table_name="community_map_points")
    op.drop_table("community_map_points")

    op.drop_index("ix_utility_providers_status", table_name="utility_providers")
    op.drop_index("ix_utility_providers_utility_type", table_name="utility_providers")
    op.drop_index("ix_utility_providers_organization_id", table_name="utility_providers")
    op.drop_table("utility_providers")

    op.drop_index("ix_password_reset_user_expires", table_name="password_reset_tokens")
    op.drop_index("ix_password_reset_tokens_token_hash", table_name="password_reset_tokens")
    op.drop_index("ix_password_reset_tokens_user_id", table_name="password_reset_tokens")
    op.drop_table("password_reset_tokens")
