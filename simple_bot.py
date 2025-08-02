#!/usr/bin/env python3
"""
Simple Telegram bot for deployment testing.
Responds to /start with "Hello world, ***username***"
"""

import asyncio
import logging
import os
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize bot
bot_token = os.getenv("BOT_TOKEN")
if not bot_token:
    raise ValueError("BOT_TOKEN environment variable is required")

bot = Bot(token=bot_token)
dp = Dispatcher()


@dp.message(Command("start"))
async def start_handler(message: types.Message) -> None:
    """Handle /start command."""
    if not message.from_user:
        await message.answer("Hello world, ***Unknown***")
        return

    username = message.from_user.username or message.from_user.first_name or "Unknown"
    await message.answer(f"Hello world, ***{username}***")
    logger.info(f"Sent greeting to user: {username}")


@dp.message()
async def default_handler(message: types.Message) -> None:
    """Handle all other messages."""
    await message.answer("Send /start to get a greeting!")


async def main() -> None:
    """Main function to start the bot."""
    logger.info("Starting simple deployment test bot")
    try:
        await dp.start_polling(bot)
    except KeyboardInterrupt:
        logger.info("Bot stopped by user")
    except Exception as e:
        logger.error(f"Bot failed to start: {e}", exc_info=True)
        raise
    finally:
        await bot.session.close()


if __name__ == "__main__":
    asyncio.run(main())
