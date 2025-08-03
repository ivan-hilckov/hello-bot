"""
User model for storing Telegram user information.
"""

from sqlalchemy import BigInteger, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    """Telegram user model."""

    __tablename__ = "users"

    # Primary key
    id: Mapped[int] = mapped_column(primary_key=True, comment="Internal user ID")

    # Telegram user information
    telegram_id: Mapped[int] = mapped_column(
        BigInteger, unique=True, index=True, comment="Telegram user ID"
    )
    username: Mapped[str | None] = mapped_column(
        String(255), nullable=True, index=True, comment="Telegram username (@username)"
    )
    first_name: Mapped[str | None] = mapped_column(
        String(255), nullable=True, comment="Telegram first name"
    )
    last_name: Mapped[str | None] = mapped_column(
        String(255), nullable=True, comment="Telegram last name"
    )

    # User state
    is_active: Mapped[bool] = mapped_column(
        default=True, index=True, comment="Whether user is active"
    )
    language_code: Mapped[str | None] = mapped_column(
        String(10), nullable=True, comment="User's language code"
    )

    # Database performance optimizations
    __table_args__ = (
        # Composite index for frequent queries (active users sorted by creation time)
        Index("ix_users_active_created", "is_active", "created_at"),
        # Composite index for user lookups by activity and last update
        Index("ix_users_active_updated", "is_active", "updated_at"),
        # Index for language-based queries
        Index("ix_users_language_active", "language_code", "is_active"),
    )

    def __str__(self) -> str:
        """Human-readable string representation."""
        display_name = self.username or self.first_name or f"User{self.telegram_id}"
        return f"User({display_name})"

    @property
    def full_name(self) -> str:
        """Get full name from first_name and last_name."""
        parts = [self.first_name, self.last_name]
        return " ".join(part for part in parts if part)

    @property
    def display_name(self) -> str:
        """Get the best display name for the user."""
        return self.username or self.full_name or f"User{self.telegram_id}"
