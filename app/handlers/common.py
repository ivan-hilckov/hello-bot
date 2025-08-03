"""
Common handlers for the bot using modern Router pattern.
"""

import logging

from aiogram import F, Router, types

logger = logging.getLogger(__name__)

# Create router instance
common_router = Router(name="common")


@common_router.message(F.text)
async def default_handler(message: types.Message) -> None:
    """Handle all other text messages."""
    await message.answer("Send /start to get a greeting!")

    if message.from_user:
        logger.info(
            f"Received unknown message from {message.from_user.username or message.from_user.first_name}"
        )
