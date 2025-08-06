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

    # Send comprehensive project information
    info_message = f"""👋 Hello <b>{user.display_name}</b>!

🤖 <b>About Hello Bot</b>
This is a production-ready Telegram bot template designed for AI-assisted development. It's built with modern Python technologies and optimized for rapid bot creation and evolution.

🚀 <b>Key Features:</b>
• AI-Optimized for collaboration with Claude, Cursor, and ChatGPT
• Production-ready with single git push deployment
• Resource efficient (optimized for 2GB VPS)
• Simple architecture (~320 lines of code)
• Built-in PostgreSQL integration

🛠️ <b>Tech Stack:</b>
• aiogram 3.0+ (Async Telegram Bot framework)
• SQLAlchemy 2.0 (Async PostgreSQL ORM)
• FastAPI (Webhook server)
• Docker + PostgreSQL

📂 <b>Repository:</b> https://github.com/ivan-hilckov/hello-bot

👨‍💻 <b>Creator:</b> https://github.com/ivan-hilckov

This template helps developers create Telegram bots quickly and evolve them systematically with AI assistance. Perfect for both beginners and experienced developers looking for a solid foundation."""

    await message.answer(info_message, parse_mode=ParseMode.HTML)


@router.message(F.text)
async def default_handler(message: types.Message) -> None:
    """Handle all other text messages with comprehensive bot information."""

    # Get user display name
    display_name = "there"
    if message.from_user:
        if message.from_user.first_name:
            display_name = message.from_user.first_name
        elif message.from_user.username:
            display_name = message.from_user.username

    # Send comprehensive project information
    info_message = f"""👋 Hello <b>{display_name}</b>!

🤖 <b>About Hello Bot</b>
This is a production-ready Telegram bot template designed for AI-assisted development. It's built with modern Python technologies and optimized for rapid bot creation and evolution.

🚀 <b>Key Features:</b>
• AI-Optimized for collaboration with Claude, Cursor, and ChatGPT
• Production-ready with single git push deployment
• Resource efficient (optimized for 2GB VPS)
• Simple architecture (~320 lines of code)
• Built-in PostgreSQL integration

🛠️ <b>Tech Stack:</b>
• aiogram 3.0+ (Async Telegram Bot framework)
• SQLAlchemy 2.0 (Async PostgreSQL ORM)
• FastAPI (Webhook server)
• Docker + PostgreSQL

📂 <b>Repository:</b> https://github.com/ivan-hilckov/hello-bot

👨‍💻 <b>Creator:</b> https://github.com/ivan-hilckov

This template helps developers create Telegram bots quickly and evolve them systematically with AI assistance. Perfect for both beginners and experienced developers looking for a solid foundation.

💡 <b>Try:</b> Send /start to register in the database and get personalized greeting!"""

    await message.answer(info_message, parse_mode=ParseMode.HTML)

    if message.from_user:
        logger.info(
            f"Received message from {message.from_user.username or message.from_user.first_name}"
        )
