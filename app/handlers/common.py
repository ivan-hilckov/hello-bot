"""
Common handlers for the bot using modern Router pattern.
"""

import logging

from aiogram import F, Router, types

from app.metrics import track_command

logger = logging.getLogger(__name__)

# Create router instance
common_router = Router(name="common")


@common_router.message(F.text)
async def default_handler(message: types.Message) -> None:
    """Handle all other text messages."""
    # Track command usage
    track_command("default")

    await message.answer("Send /start to get a greeting!")

    if message.from_user:
        logger.info(
            f"Received unknown message from {message.from_user.username or message.from_user.first_name}"
        )
