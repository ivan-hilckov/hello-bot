"""
Handler for /start command using modern Router pattern.
"""

import structlog
from aiogram import Router, types
from aiogram.enums import ParseMode
from aiogram.filters import Command
from sqlalchemy.ext.asyncio import AsyncSession

from app.logging import log_user_interaction
from app.services.user import UserService

logger = structlog.get_logger(__name__)

# Create router instance
start_router = Router(name="start")


@start_router.message(Command("start"))
async def start_handler(message: types.Message, session: AsyncSession) -> None:
    """
    Handle /start command.

    Creates or updates user record in database and sends personalized greeting.

    Args:
        message: Telegram message object containing user info
        session: Database session injected by middleware

    Returns:
        None

    Raises:
        HTTPException: If user creation fails
        DatabaseError: If database is unreachable

    Example:
        User sends: /start
        Bot responds: "Hello world test deploy 🪏, <b>@username</b>"
    """
    if not message.from_user:
        await message.answer("Hello world, <b>Unknown</b>", parse_mode=ParseMode.HTML)
        return

    # Get or create user in database using service layer
    user_service = UserService(session)
    user = await user_service.get_or_create_user(message.from_user)

    # Send greeting
    greeting = f"Hello world test deploy 🪏, <b>{user.display_name}</b>"
    await message.answer(greeting, parse_mode=ParseMode.HTML)

    log_user_interaction(
        logger,
        "Sent greeting to user",
        user_id=user.telegram_id,
        username=user.username,
        command="start",
        display_name=user.display_name,
    )
