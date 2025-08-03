"""
Base service class for dependency injection and transaction management.
"""

from sqlalchemy.ext.asyncio import AsyncSession


class BaseService:
    """
    Base service class with common functionality.

    Provides access to database session and common operations.
    """

    def __init__(self, session: AsyncSession) -> None:
        """
        Initialize service with database session.

        Args:
            session: Database session for operations
        """
        self.session = session

    async def commit(self) -> None:
        """Commit current transaction."""
        await self.session.commit()

    async def rollback(self) -> None:
        """Rollback current transaction."""
        await self.session.rollback()

    async def flush(self) -> None:
        """Flush pending changes to database."""
        await self.session.flush()

    async def refresh(self, instance: object) -> None:
        """
        Refresh instance from database.

        Args:
            instance: SQLAlchemy model instance to refresh
        """
        await self.session.refresh(instance)
