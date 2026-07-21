"""enhance vacation mode

Revision ID: 28cdbe26e564
Revises: 5972443fc195
Create Date: 2026-07-21 15:28:31.406564
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "28cdbe26e564"
down_revision: Union[str, Sequence[str], None] = "5972443fc195"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # ------------------------------------------------------------------
    # Add new columns (nullable initially for existing records)
    # ------------------------------------------------------------------

    op.add_column(
        "vacation_modes",
        sa.Column("visitor_policy", sa.String(length=30), nullable=True),
    )

    op.add_column(
        "vacation_modes",
        sa.Column("delivery_policy", sa.String(length=30), nullable=True),
    )

    op.add_column(
        "vacation_modes",
        sa.Column("activated_at", sa.DateTime(), nullable=True),
    )

    op.add_column(
        "vacation_modes",
        sa.Column("deactivated_at", sa.DateTime(), nullable=True),
    )

    op.add_column(
        "vacation_modes",
        sa.Column("updated_at", sa.DateTime(), nullable=True),
    )

    # ------------------------------------------------------------------
    # Migrate existing data
    # ------------------------------------------------------------------

    op.execute("""
        UPDATE vacation_modes
        SET visitor_policy =
            CASE
                WHEN allow_visitors = TRUE THEN 'ALLOW_ALL'
                ELSE 'REJECT_ALL'
            END
    """)

    op.execute("""
        UPDATE vacation_modes
        SET delivery_policy =
            CASE
                WHEN allow_deliveries = TRUE THEN 'ALLOW'
                ELSE 'REJECT'
            END
    """)

    op.execute("""
        UPDATE vacation_modes
        SET status = 'SCHEDULED'
        WHERE status IS NULL
    """)

    # ------------------------------------------------------------------
    # Make new columns NOT NULL
    # ------------------------------------------------------------------

    op.alter_column(
        "vacation_modes",
        "visitor_policy",
        nullable=False,
    )

    op.alter_column(
        "vacation_modes",
        "delivery_policy",
        nullable=False,
    )

    # ------------------------------------------------------------------
    # Create indexes
    # ------------------------------------------------------------------

    op.create_index(
        "idx_vacation_resident",
        "vacation_modes",
        ["resident_id"],
        unique=False,
    )

    op.create_index(
        "idx_vacation_status",
        "vacation_modes",
        ["status"],
        unique=False,
    )

    op.create_index(
        "idx_vacation_dates",
        "vacation_modes",
        ["start_date", "end_date"],
        unique=False,
    )

    # ------------------------------------------------------------------
    # Remove old columns
    # ------------------------------------------------------------------

    op.drop_column(
        "vacation_modes",
        "allow_visitors",
    )

    op.drop_column(
        "vacation_modes",
        "allow_deliveries",
    )


def downgrade() -> None:
    """Downgrade schema."""

    # ------------------------------------------------------------------
    # Restore old columns
    # ------------------------------------------------------------------

    op.add_column(
        "vacation_modes",
        sa.Column("allow_visitors", sa.Boolean(), nullable=True),
    )

    op.add_column(
        "vacation_modes",
        sa.Column("allow_deliveries", sa.Boolean(), nullable=True),
    )

    # ------------------------------------------------------------------
    # Restore data
    # ------------------------------------------------------------------

    op.execute("""
        UPDATE vacation_modes
        SET allow_visitors =
            CASE
                WHEN visitor_policy = 'ALLOW_ALL' THEN TRUE
                ELSE FALSE
            END
    """)

    op.execute("""
        UPDATE vacation_modes
        SET allow_deliveries =
            CASE
                WHEN delivery_policy = 'ALLOW' THEN TRUE
                ELSE FALSE
            END
    """)

    op.alter_column(
        "vacation_modes",
        "allow_visitors",
        nullable=False,
    )

    op.alter_column(
        "vacation_modes",
        "allow_deliveries",
        nullable=False,
    )

    # ------------------------------------------------------------------
    # Drop indexes
    # ------------------------------------------------------------------

    op.drop_index(
        "idx_vacation_dates",
        table_name="vacation_modes",
    )

    op.drop_index(
        "idx_vacation_status",
        table_name="vacation_modes",
    )

    op.drop_index(
        "idx_vacation_resident",
        table_name="vacation_modes",
    )

    # ------------------------------------------------------------------
    # Drop new columns
    # ------------------------------------------------------------------

    op.drop_column(
        "vacation_modes",
        "updated_at",
    )

    op.drop_column(
        "vacation_modes",
        "deactivated_at",
    )

    op.drop_column(
        "vacation_modes",
        "activated_at",
    )

    op.drop_column(
        "vacation_modes",
        "delivery_policy",
    )

    op.drop_column(
        "vacation_modes",
        "visitor_policy",
    )