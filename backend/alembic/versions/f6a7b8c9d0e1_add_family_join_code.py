"""add family join code to units"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "f6a7b8c9d0e1"
down_revision: Union[str, Sequence[str], None] = "e5f6a7b8c9d0"
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column("units", sa.Column("family_join_code", sa.String(length=24), nullable=True))
    op.create_index("ix_units_family_join_code", "units", ["family_join_code"], unique=True)

def downgrade() -> None:
    op.drop_index("ix_units_family_join_code", table_name="units")
    op.drop_column("units", "family_join_code")
