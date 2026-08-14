from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base_class import Base


class UserBlockScope(Base):
    """Access scope for non-community-wide administrators.

    The existing SafeColony model calls the property subdivision a `Section`.
    For apartment communities this is the same concept as a Block, so this
    table deliberately references sections instead of introducing a second
    duplicate hierarchy.
    """

    __tablename__ = "user_block_scopes"
    __table_args__ = (
        UniqueConstraint("user_id", "section_id", name="uq_user_block_scope"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    section_id: Mapped[int] = mapped_column(
        ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    user = relationship("User", back_populates="block_scopes")
    section = relationship("Section", back_populates="admin_scopes")
