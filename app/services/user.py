"""
User service for user-related business logic.
"""

import structlog
from aiogram import types
from sqlalchemy import select

from app.cache import cache_service
from app.database.models import User
from app.logging import log_user_interaction
from app.metrics import track_database_operation
from app.services.base import BaseService

logger = structlog.get_logger(__name__)


class UserService(BaseService):
    """Service for user-related operations."""

    async def get_or_create_user(self, telegram_user: types.User) -> User:
        """
        Get existing user or create new one from Telegram user data.

        Args:
            telegram_user: Telegram user object from message

        Returns:
            User: Database user instance

        Raises:
            Exception: If user creation/update fails
        """
        # Try to find existing user
        stmt = select(User).where(User.telegram_id == telegram_user.id)
        result = await self.session.execute(stmt)
        user = result.scalar_one_or_none()
        track_database_operation("select", "users")

        if user:
            # Update user information if changed
            updated = await self._update_user_if_changed(user, telegram_user)
            if updated:
                await self.flush()
                track_database_operation("update", "users")
                log_user_interaction(
                    logger,
                    "Updated user info",
                    user_id=user.telegram_id,
                    username=user.username,
                    display_name=user.display_name,
                )
        else:
            # Create new user
            user = await self._create_new_user(telegram_user)
            log_user_interaction(
                logger,
                "Created new user",
                user_id=user.telegram_id,
                username=user.username,
                display_name=user.display_name,
            )

        return user

    async def _update_user_if_changed(self, user: User, telegram_user: types.User) -> bool:
        """
        Update user fields if they have changed.

        Args:
            user: Existing database user
            telegram_user: Current Telegram user data

        Returns:
            bool: True if any field was updated
        """
        updated = False

        if user.username != telegram_user.username:
            user.username = telegram_user.username
            updated = True

        if user.first_name != telegram_user.first_name:
            user.first_name = telegram_user.first_name
            updated = True

        if user.last_name != telegram_user.last_name:
            user.last_name = telegram_user.last_name
            updated = True

        if user.language_code != telegram_user.language_code:
            user.language_code = telegram_user.language_code
            updated = True

        return updated

    async def _create_new_user(self, telegram_user: types.User) -> User:
        """
        Create new user from Telegram user data.

        Args:
            telegram_user: Telegram user object

        Returns:
            User: New database user instance
        """
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            last_name=telegram_user.last_name,
            language_code=telegram_user.language_code,
            is_active=True,
        )
        self.session.add(user)
        await self.flush()
        track_database_operation("insert", "users")
        return user

    async def get_user_by_telegram_id(self, telegram_id: int) -> User | None:
        """
        Get user by Telegram ID with caching.

        Args:
            telegram_id: Telegram user ID

        Returns:
            User | None: User if found, None otherwise
        """
        # Try cache first
        cache_key = f"user:telegram_id:{telegram_id}"
        cached_user = await cache_service.get(cache_key)
        if cached_user:
            return cached_user

        # Database query
        stmt = select(User).where(User.telegram_id == telegram_id)
        result = await self.session.execute(stmt)
        user = result.scalar_one_or_none()
        track_database_operation("select", "users")

        # Cache result if found
        if user:
            await cache_service.set(cache_key, user, ttl=300)  # 5 minutes

        return user

    async def activate_user(self, user: User) -> User:
        """
        Activate user account.

        Args:
            user: User to activate

        Returns:
            User: Updated user instance
        """
        user.is_active = True
        await self.flush()
        log_user_interaction(
            logger,
            "Activated user",
            user_id=user.telegram_id,
            username=user.username,
            display_name=user.display_name,
            status="activated",
        )
        return user

    async def deactivate_user(self, user: User) -> User:
        """
        Deactivate user account.

        Args:
            user: User to deactivate

        Returns:
            User: Updated user instance
        """
        user.is_active = False
        await self.flush()
        log_user_interaction(
            logger,
            "Deactivated user",
            user_id=user.telegram_id,
            username=user.username,
            display_name=user.display_name,
            status="deactivated",
        )
        return user
