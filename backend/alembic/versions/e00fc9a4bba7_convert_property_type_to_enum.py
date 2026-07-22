"""convert property_type to enum

Revision ID: e00fc9a4bba7
Revises: 910ed72a2973
Create Date: 2026-07-22 13:31:22.629306
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e00fc9a4bba7"
down_revision: Union[str, Sequence[str], None] = "910ed72a2973"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


property_type_enum = sa.Enum(
    "APARTMENT",
    "VILLA",
    "GATED_COMMUNITY",
    "COMMERCIAL",
    "MIXED_USE",
    name="propertytype",
)


def upgrade() -> None:
    # Create PostgreSQL enum type
    property_type_enum.create(op.get_bind(), checkfirst=True)

    # Normalize existing values (only needed if data already exists)
    op.execute("""
        UPDATE properties
        SET property_type = UPPER(property_type);
    """)

    # Convert column from VARCHAR -> ENUM
    op.alter_column(
        "properties",
        "property_type",
        existing_type=sa.String(),
        type_=property_type_enum,
        postgresql_using="property_type::propertytype",
        existing_nullable=False,
    )


def downgrade() -> None:
    # Convert ENUM -> VARCHAR
    op.alter_column(
        "properties",
        "property_type",
        existing_type=property_type_enum,
        type_=sa.String(),
        postgresql_using="property_type::text",
        existing_nullable=False,
    )

    # Drop enum type
    property_type_enum.drop(op.get_bind(), checkfirst=True)