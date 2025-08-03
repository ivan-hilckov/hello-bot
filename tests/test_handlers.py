"""
Tests for bot handlers.
"""

from aiogram.types import User as TelegramUser
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import User
from app.services.user import UserService


class TestStartHandler:
    """Test cases for /start command handler."""

    async def test_user_service_create_new_user(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test creating a new user via UserService."""
        # Arrange
        user_service = UserService(test_session)

        # Act
        user = await user_service.get_or_create_user(telegram_user)
        await test_session.commit()

        # Assert
        assert user.telegram_id == telegram_user.id
        assert user.username == telegram_user.username
        assert user.first_name == telegram_user.first_name
        assert user.last_name == telegram_user.last_name
        assert user.language_code == telegram_user.language_code
        assert user.is_active is True

        # Verify user is in database
        result = await test_session.execute(
            select(User).where(User.telegram_id == telegram_user.id)
        )
        db_user = result.scalar_one_or_none()
        assert db_user is not None
        assert db_user.telegram_id == telegram_user.id

    async def test_user_service_update_existing_user(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test updating an existing user via UserService."""
        # Arrange - create user first
        existing_user = User(
            telegram_id=telegram_user.id,
            username="old_username",
            first_name="Old",
            last_name="Name",
            language_code="ru",
            is_active=True,
        )
        test_session.add(existing_user)
        await test_session.commit()

        # Act - update user through service
        user_service = UserService(test_session)
        user = await user_service.get_or_create_user(telegram_user)
        await test_session.commit()

        # Assert - user was updated
        assert user.id == existing_user.id  # Same database ID
        assert user.username == telegram_user.username  # Updated
        assert user.first_name == telegram_user.first_name  # Updated
        assert user.last_name == telegram_user.last_name  # Updated
        assert user.language_code == telegram_user.language_code  # Updated

    async def test_start_handler_creates_user_in_database(
        self, telegram_user: TelegramUser, test_session: AsyncSession
    ) -> None:
        """Test that start handler creates user in database via service layer."""
        # Act - test business logic through service
        user_service = UserService(test_session)
        user = await user_service.get_or_create_user(telegram_user)
        await test_session.commit()

        # Assert - user should be created with correct data
        assert user.telegram_id == telegram_user.id
        assert user.username == telegram_user.username
        assert user.first_name == telegram_user.first_name
        assert user.is_active is True

        # Verify user persisted in database
        result = await test_session.execute(
            select(User).where(User.telegram_id == telegram_user.id)
        )
        db_user = result.scalar_one_or_none()
        assert db_user is not None
        assert db_user.telegram_id == telegram_user.id
