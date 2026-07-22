"""add unit enums

Revision ID: d656f9fff766
Revises: 1a13529bff87
Create Date: 2026-07-22
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d656f9fff766"
down_revision: Union[str, Sequence[str], None] = "1a13529bff87"
branch_labels = None
depends_on = None


unit_type_enum = sa.Enum(
    "APARTMENT",
    "VILLA",
    "SHOP",
    "OFFICE",
    name="unittype",
)


occupancy_status_enum = sa.Enum(
    "VACANT",
    "OCCUPIED",
    "RESERVED",
    "BLOCKED",
    name="occupancystatus",
)


def upgrade() -> None:

    # Create PostgreSQL enum types first
    unit_type_enum.create(
        op.get_bind(),
        checkfirst=True,
    )

    occupancy_status_enum.create(
        op.get_bind(),
        checkfirst=True,
    )


    # Convert existing data
    op.execute("""
        UPDATE units
        SET unit_type = 'APARTMENT'
        WHERE unit_type IS NULL;
    """)


    op.execute("""
        UPDATE units
        SET occupancy_status = 'VACANT'
        WHERE occupancy_status IS NULL;
    """)


    # Change columns to enum
    op.alter_column(
        "units",
        "unit_type",
        existing_type=sa.VARCHAR(length=30),
        type_=unit_type_enum,
        postgresql_using="unit_type::unittype",
        existing_nullable=False,
    )


    op.alter_column(
        "units",
        "occupancy_status",
        existing_type=sa.VARCHAR(length=30),
        type_=occupancy_status_enum,
        postgresql_using="occupancy_status::occupancystatus",
        existing_nullable=False,
    )


def downgrade() -> None:

    op.alter_column(
        "units",
        "unit_type",
        existing_type=unit_type_enum,
        type_=sa.VARCHAR(length=30),
        postgresql_using="unit_type::text",
    )


    op.alter_column(
        "units",
        "occupancy_status",
        existing_type=occupancy_status_enum,
        type_=sa.VARCHAR(length=30),
        postgresql_using="occupancy_status::text",
    )


    unit_type_enum.drop(
        op.get_bind(),
        checkfirst=True,
    )

    occupancy_status_enum.drop(
        op.get_bind(),
        checkfirst=True,
    )