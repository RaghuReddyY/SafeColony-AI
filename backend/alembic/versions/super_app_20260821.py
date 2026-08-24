"""SafeColony super app phases 2-7 extensions
Revision ID: super_app_20260821
Revises: marketplace_20260821
"""
from alembic import op
import sqlalchemy as sa

revision="super_app_20260821"
down_revision="marketplace_20260821_enhancements"
branch_labels=None
depends_on=None

def upgrade():
    op.create_table("service_requests",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("resident_user_id",sa.Integer(),sa.ForeignKey("users.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("provider_id",sa.Integer(),sa.ForeignKey("community_services.id",ondelete="SET NULL")),
        sa.Column("category",sa.String(60),nullable=False,index=True),sa.Column("title",sa.String(160),nullable=False),sa.Column("description",sa.Text()),sa.Column("preferred_slot",sa.String(100)),
        sa.Column("status",sa.String(30),nullable=False,server_default="REQUESTED"),sa.Column("quoted_amount",sa.Numeric(12,2)),sa.Column("payment_status",sa.String(20),nullable=False,server_default="PENDING"),
        sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False),sa.Column("updated_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False))
    op.create_table("vendor_offers",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("vendor_id",sa.Integer(),sa.ForeignKey("marketplace_vendors.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("event_id",sa.Integer(),sa.ForeignKey("marketplace_events.id",ondelete="SET NULL")),
        sa.Column("title",sa.String(160),nullable=False),sa.Column("description",sa.Text()),sa.Column("discount_percent",sa.Numeric(5,2),nullable=False,server_default="0"),sa.Column("min_orders",sa.Integer(),nullable=False,server_default="1"),sa.Column("is_active",sa.Boolean(),nullable=False,server_default="true"),sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False))
    op.create_table("vendor_ratings",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("vendor_id",sa.Integer(),sa.ForeignKey("marketplace_vendors.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("resident_user_id",sa.Integer(),sa.ForeignKey("users.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("order_id",sa.Integer(),sa.ForeignKey("marketplace_orders.id",ondelete="SET NULL")),
        sa.Column("rating",sa.Integer(),nullable=False),sa.Column("quality",sa.Integer()),sa.Column("price",sa.Integer()),sa.Column("delivery",sa.Integer()),sa.Column("comment",sa.Text()),sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False))
    op.create_table("community_parcels",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("order_id",sa.Integer(),sa.ForeignKey("marketplace_orders.id",ondelete="CASCADE"),nullable=False,unique=True),sa.Column("apartment_label",sa.String(80),nullable=False),sa.Column("hub",sa.String(120),nullable=False,server_default="Main Gate"),
        sa.Column("pickup_code",sa.String(20),nullable=False),sa.Column("status",sa.String(30),nullable=False,server_default="AT_HUB"),sa.Column("handed_to_user_id",sa.Integer(),sa.ForeignKey("users.id",ondelete="SET NULL")),sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False),sa.Column("picked_up_at",sa.DateTime(timezone=True)))
    op.create_table("utility_bills",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("resident_user_id",sa.Integer(),sa.ForeignKey("users.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("utility_type",sa.String(40),nullable=False,index=True),sa.Column("provider_name",sa.String(120),nullable=False),sa.Column("account_reference",sa.String(120)),sa.Column("amount",sa.Numeric(12,2),nullable=False),sa.Column("due_date",sa.DateTime(timezone=True)),sa.Column("status",sa.String(20),nullable=False,server_default="PENDING"),sa.Column("payment_reference",sa.String(120)),sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False))
    op.create_table("recurring_orders",
        sa.Column("id",sa.Integer(),primary_key=True),sa.Column("organization_id",sa.Integer(),sa.ForeignKey("organizations.id",ondelete="CASCADE"),nullable=False,index=True),sa.Column("resident_user_id",sa.Integer(),sa.ForeignKey("users.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("category",sa.String(60),nullable=False),sa.Column("description",sa.String(255),nullable=False),sa.Column("cadence",sa.String(40),nullable=False),sa.Column("preferred_day",sa.String(20)),sa.Column("preferred_slot",sa.String(100)),sa.Column("active",sa.Boolean(),nullable=False,server_default="true"),sa.Column("created_at",sa.DateTime(timezone=True),server_default=sa.func.now(),nullable=False))

def downgrade():
    for t in ["recurring_orders","utility_bills","community_parcels","vendor_ratings","vendor_offers","service_requests"]:
        op.drop_table(t)
