"""add vehicle guard operations

Revision ID: 5972443fc195
Revises: 2e0d73c5f0f5
Create Date: 2026-07-21 14:28:38.467643

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5972443fc195'
down_revision: Union[str, Sequence[str], None] = '2e0d73c5f0f5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():

    op.add_column(
        "vehicles",
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default="OUTSIDE",
        ),
    )

    op.add_column(
        "vehicles",
        sa.Column(
            "entry_time",
            sa.DateTime(),
            nullable=True,
        ),
    )

    op.add_column(
        "vehicles",
        sa.Column(
            "exit_time",
            sa.DateTime(),
            nullable=True,
        ),
    )

    op.add_column(
        "vehicles",
        sa.Column(
            "entered_by",
            sa.String(length=100),
            nullable=True,
        ),
    )

    op.add_column(
        "vehicles",
        sa.Column(
            "exited_by",
            sa.String(length=100),
            nullable=True,
        ),
    )

    op.create_index(
        "ix_vehicles_status",
        "vehicles",
        ["status"],
    )


def downgrade():

    op.drop_index(
        "ix_vehicles_status",
        table_name="vehicles",
    )

    op.drop_column(
        "vehicles",
        "exited_by",
    )

    op.drop_column(
        "vehicles",
        "entered_by",
    )

    op.drop_column(
        "vehicles",
        "exit_time",
    )

    op.drop_column(
        "vehicles",
        "entry_time",
    )

    op.drop_column(
        "vehicles",
        "status",
    )