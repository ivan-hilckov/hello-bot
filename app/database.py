"""
Simple database module combining models, session, and engine.
"""

from collections.abc import AsyncGenerator
from datetime import datetime

from sqlalchemy import BigInteger, String, func
from sqlalchemy.ext.asyncio import AsyncAttrs, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.config import settings


# Base class for all models
class Base(AsyncAttrs, DeclarativeBase):
    """Base class for all database models."""

    __abstract__: bool = True


class TimestampMixin:
    """Mixin to add created_at and updated_at timestamps."""

    created_at: Mapped[datetime] = mapped_column(default=func.now(), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now(), onupdate=func.now()
    )


class User(Base, TimestampMixin):
    """Telegram user model."""

    __tablename__: str = "users"

    # Primary key
    id: Mapped[int] = mapped_column(primary_key=True)

    # Telegram user information
    telegram_id: Mapped[int] = mapped_column(BigInteger, unique=True, index=True)
    username: Mapped[str | None] = mapped_column(String(255), nullable=True)
    first_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # User state
    is_active: Mapped[bool] = mapped_column(default=True)
    language_code: Mapped[str | None] = mapped_column(String(10), nullable=True)

    @property
    def display_name(self) -> str:
        """Get the best display name for the user."""
        return self.username or self.full_name or f"User{self.telegram_id}"

    @property
    def full_name(self) -> str:
        """Get full name from first_name and last_name."""
        parts = [self.first_name, self.last_name]
        return " ".join(part for part in parts if part)


# Create engine and session with optimized pool for shared PostgreSQL
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
    pool_size=2,  # Reduced per bot (shared instance)
    max_overflow=3,  # Reduced overflow
    pool_timeout=30,
    pool_recycle=3600,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def create_tables() -> None:
    """Create all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
