from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base_class import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)

    full_name: Mapped[str] = mapped_column(String(100))

    email: Mapped[str] = mapped_column(String(120), unique=True)

    phone: Mapped[str] = mapped_column(String(20), unique=True)

    password: Mapped[str] = mapped_column(String(255))

    role: Mapped[str] = mapped_column(
        String(30),
        default="resident"
    )