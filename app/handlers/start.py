"""
Handler for /start command.
"""

import logging

from aiogram import types
from aiogram.enums import ParseMode
from aiogram.filters import Command
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import User

logger = logging.getLogger(__name__)


async def get_or_create_user(session: AsyncSession, telegram_user: types.User) -> User:
    """Get existing user or create new one."""

    # Try to find existing user
    result = await session.execute(select(User).where(User.telegram_id == telegram_user.id))
    user = result.scalar_one_or_none()

    if user:
        # Update user information if changed
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

        if updated:
            await session.flush()
            logger.info(f"Updated user info for {user.display_name}")
    else:
        # Create new user
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            last_name=telegram_user.last_name,
            language_code=telegram_user.language_code,
            is_active=True,
        )
        session.add(user)
        await session.flush()
        logger.info(f"Created new user: {user.display_name}")

    return user


async def start_handler(message: types.Message, session: AsyncSession) -> None:
    """Handle /start command."""
    if not message.from_user:
        await message.answer("Hello world, <b>Unknown</b>", parse_mode=ParseMode.HTML)
        return

    # Get or create user in database
    user = await get_or_create_user(session, message.from_user)

    # Send greeting
    greeting = f"Hello world test deploy, <b>{user.display_name}</b>"
    await message.answer(greeting, parse_mode=ParseMode.HTML)

    logger.info(f"Sent greeting to user: {user.display_name} (ID: {user.telegram_id})")


# Register handler function
def register_start_handlers(dp):
    """Register start command handlers."""
    dp.message.register(start_handler, Command("start"))
