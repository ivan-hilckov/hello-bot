"""
Tests for service layer.
"""

from aiogram.types import User as TelegramUser
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import User
from app.services.user import UserService


class TestUserService:
    """Test cases for UserService."""

    async def test_get_user_by_telegram_id_found(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test getting user by Telegram ID when user exists."""
        # Arrange
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            is_active=True,
        )
        test_session.add(user)
        await test_session.commit()

        # Act
        user_service = UserService(test_session)
        found_user = await user_service.get_user_by_telegram_id(telegram_user.id)

        # Assert
        assert found_user is not None
        assert found_user.telegram_id == telegram_user.id
        assert found_user.username == telegram_user.username

    async def test_get_user_by_telegram_id_not_found(self, test_session: AsyncSession) -> None:
        """Test getting user by Telegram ID when user doesn't exist."""
        # Act
        user_service = UserService(test_session)
        found_user = await user_service.get_user_by_telegram_id(999999999)

        # Assert
        assert found_user is None

    async def test_activate_user(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test activating a user."""
        # Arrange
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            is_active=False,  # Start deactivated
        )
        test_session.add(user)
        await test_session.commit()

        # Act
        user_service = UserService(test_session)
        activated_user = await user_service.activate_user(user)
        await test_session.commit()

        # Assert
        assert activated_user.is_active is True

        # Verify in database
        result = await test_session.execute(select(User).where(User.id == user.id))
        db_user = result.scalar_one()
        assert db_user.is_active is True

    async def test_deactivate_user(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test deactivating a user."""
        # Arrange
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            is_active=True,  # Start activated
        )
        test_session.add(user)
        await test_session.commit()

        # Act
        user_service = UserService(test_session)
        deactivated_user = await user_service.deactivate_user(user)
        await test_session.commit()

        # Assert
        assert deactivated_user.is_active is False

        # Verify in database
        result = await test_session.execute(select(User).where(User.id == user.id))
        db_user = result.scalar_one()
        assert db_user.is_active is False

    async def test_user_update_no_changes(
        self, test_session: AsyncSession, telegram_user: TelegramUser
    ) -> None:
        """Test that user update returns False when no changes are needed."""
        # Arrange
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            last_name=telegram_user.last_name,
            language_code=telegram_user.language_code,
            is_active=True,
        )
        test_session.add(user)
        await test_session.commit()

        # Act
        user_service = UserService(test_session)
        updated = await user_service._update_user_if_changed(user, telegram_user)

        # Assert
        assert updated is False
