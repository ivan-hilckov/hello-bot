"""
Database middleware for aiogram bot.
"""

from collections.abc import Awaitable, Callable
from typing import Any

from aiogram import BaseMiddleware
from aiogram.types import TelegramObject

from app.database.session import AsyncSessionLocal


class DatabaseMiddleware(BaseMiddleware):
    """Middleware to inject database session into handlers."""

    async def __call__(
        self,
        handler: Callable[[TelegramObject, dict[str, Any]], Awaitable[Any]],
        event: TelegramObject,
        data: dict[str, Any],
    ) -> Any:
        """Inject database session into handler data."""
        async with AsyncSessionLocal() as session:
            try:
                # Add session to handler data
                data["session"] = session

                # Call the handler
                result = await handler(event, data)

                # Commit the transaction
                await session.commit()
                return result

            except Exception:
                # Rollback on error
                await session.rollback()
                raise
            finally:
                # Session will be closed automatically by context manager
                pass
