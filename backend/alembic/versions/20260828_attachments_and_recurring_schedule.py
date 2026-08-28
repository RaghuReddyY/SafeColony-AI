"""add complaint/chat attachments and recurring schedule fields
Revision ID: 20260828_attachments_and_recurring_schedule
Revises: 20260828_recurring_vendor
"""
from alembic import op
import sqlalchemy as sa
revision = "20260828_attachments_and_recurring_schedule"
down_revision = "20260828_recurring_vendor"
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "complaint_attachments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("complaint_id", sa.Integer(), sa.ForeignKey("complaints.id", ondelete="CASCADE"), nullable=False),
        sa.Column("uploaded_by_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("content_type", sa.String(120), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_complaint_attachments_complaint_id", "complaint_attachments", ["complaint_id"])
    op.create_table(
        "chat_attachments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("message_id", sa.Integer(), sa.ForeignKey("chat_messages.id", ondelete="CASCADE"), nullable=False),
        sa.Column("uploaded_by_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("content_type", sa.String(120), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_chat_attachments_message_id", "chat_attachments", ["message_id"])
    op.add_column("recurring_orders", sa.Column("next_run_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("recurring_orders", sa.Column("last_run_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("recurring_orders", sa.Column("last_generated_order_id", sa.Integer(), nullable=True))
    op.create_index("ix_recurring_orders_next_run_at", "recurring_orders", ["next_run_at"])

def downgrade():
    op.drop_index("ix_recurring_orders_next_run_at", table_name="recurring_orders")
    op.drop_column("recurring_orders", "last_generated_order_id")
    op.drop_column("recurring_orders", "last_run_at")
    op.drop_column("recurring_orders", "next_run_at")
    op.drop_index("ix_chat_attachments_message_id", table_name="chat_attachments")
    op.drop_table("chat_attachments")
    op.drop_index("ix_complaint_attachments_complaint_id", table_name="complaint_attachments")
    op.drop_table("complaint_attachments")
