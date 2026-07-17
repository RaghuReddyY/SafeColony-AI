"""add walk in visitor support

Revision ID: 747219b354fe
Revises: 79a7c09a7b82
Create Date: 2026-07-17 23:45:44.021551

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '747219b354fe'
down_revision: Union[str, Sequence[str], None] = '79a7c09a7b82'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade():

    op.add_column(
        "visitors",
        sa.Column(
            "entry_mode",
            sa.String(length=20),
            nullable=False,
            server_default="QR",
        ),
    )

    op.add_column(
        "visitors",
        sa.Column(
            "approval_mode",
            sa.String(length=20),
            nullable=True,
        ),
    )

    op.add_column(
        "visitors",
        sa.Column(
            "visitor_photo",
            sa.String(length=255),
            nullable=True,
        ),
    )

    op.add_column(
        "visitors",
        sa.Column(
            "created_by_guard",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )

def downgrade():

    op.drop_column("visitors", "created_by_guard")
    op.drop_column("visitors", "visitor_photo")
    op.drop_column("visitors", "approval_mode")
    op.drop_column("visitors", "entry_mode")
