"""
All bot handlers in one file.
"""

import logging

from aiogram import F, Router, types
from aiogram.enums import ParseMode
from aiogram.filters import Command
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import User

logger = logging.getLogger(__name__)

# Create router
router = Router()


@router.message(Command("start"))
async def start_handler(message: types.Message, session: AsyncSession) -> None:
    """Handle /start command."""
    if not message.from_user:
        await message.answer(
            f"Hello! Welcome to {settings.project_name}, <b>Unknown</b>", parse_mode=ParseMode.HTML
        )
        return

    telegram_user = message.from_user

    # Get or create user
    stmt = select(User).where(User.telegram_id == telegram_user.id)
    result = await session.execute(stmt)
    user = result.scalar_one_or_none()

    if user:
        # Update existing user
        user.username = telegram_user.username
        user.first_name = telegram_user.first_name
        user.last_name = telegram_user.last_name
        user.language_code = telegram_user.language_code
        logger.info(f"Updated user: {user.display_name}")
    else:
        # Create new user
        user = User(
            telegram_id=telegram_user.id,
            username=telegram_user.username,
            first_name=telegram_user.first_name,
            last_name=telegram_user.last_name,
            language_code=telegram_user.language_code,
        )
        session.add(user)
        logger.info(f"Created new user: {user.display_name}")

    await session.commit()

    # Send greeting
    greeting = f"Hello! Welcome to {settings.project_name}, 😎 <b>{user.display_name}</b>"
    await message.answer(greeting, parse_mode=ParseMode.HTML)


@router.message(F.text)
async def default_handler(message: types.Message) -> None:
    """Handle all other text messages."""
    await message.answer("Send /start to get a greeting!")

    if message.from_user:
        logger.info(
            f"Received message from {message.from_user.username or message.from_user.first_name}"
        )
