"""
Handler for /start command using modern Router pattern.
"""

import structlog
from aiogram import Router, types
from aiogram.enums import ParseMode
from aiogram.filters import Command
from sqlalchemy.ext.asyncio import AsyncSession

from app.container import inject_services
from app.logging import log_user_interaction
from app.metrics import track_command
from app.services.user import UserService

logger = structlog.get_logger(__name__)

# Create router instance
start_router = Router(name="start")


@start_router.message(Command("start"))
@inject_services(UserService)
async def start_handler(
    message: types.Message, session: AsyncSession, user_service: UserService
) -> None:
    """
    Handle /start command.

    Creates or updates user record in database and sends personalized greeting.
    Uses dependency injection to get UserService instance.

    Args:
        message: Telegram message object containing user info
        session: Database session injected by middleware
        user_service: UserService injected by DI container

    Returns:
        None

    Raises:
        HTTPException: If user creation fails
        DatabaseError: If database is unreachable

    Example:
        User sends: /start
        Bot responds: "Hello! Welcome to the bot, <b>@username</b>"
    """
    if not message.from_user:
        await message.answer("Hello! Welcome to the bot, <b>Unknown</b>", parse_mode=ParseMode.HTML)
        return

    # Track command usage
    track_command("start")

    # Get or create user using injected service
    user = await user_service.get_or_create_user(message.from_user)

    # Send greeting
    greeting = f"Hello! Welcome to the bot, <b>{user.display_name}</b>"
    await message.answer(greeting, parse_mode=ParseMode.HTML)

    log_user_interaction(
        logger,
        "Sent greeting to user",
        user_id=user.telegram_id,
        username=user.username,
        command="start",
        display_name=user.display_name,
    )
