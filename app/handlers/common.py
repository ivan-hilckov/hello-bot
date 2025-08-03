"""
Common handlers for the bot.
"""

import logging

from aiogram import types

logger = logging.getLogger(__name__)


async def default_handler(message: types.Message) -> None:
    """Handle all other messages."""
    await message.answer("Send /start to get a greeting!")

    if message.from_user:
        logger.info(
            f"Received unknown message from {message.from_user.username or message.from_user.first_name}"
        )


def register_common_handlers(dp):
    """Register common handlers."""
    # This will handle all messages that weren't handled by other handlers
    dp.message.register(default_handler)
