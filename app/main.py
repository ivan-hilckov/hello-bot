"""
Simple main application entry point.
"""

import asyncio
import logging
from typing import Any

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.types import Update
from fastapi import FastAPI

from app.config import settings
from app.database import create_tables, engine
from app.handlers import router
from app.middleware import DatabaseMiddleware


async def main() -> None:
    """Main application function."""
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # Create database tables
    await create_tables()
    logger.info("Database initialized")

    # Create bot and dispatcher
    logger.info("Bot token: %s", settings.bot_token)

    bot = Bot(
        token=settings.bot_token,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML),
    )
    dp = Dispatcher()

    # Add middleware and router
    dp.message.middleware(DatabaseMiddleware())
    dp.include_router(router)

    try:
        if settings.webhook_url:
            # Simple webhook mode
            logger.info(f"Starting webhook mode: {settings.webhook_url}")

            # Create simple FastAPI app
            app = FastAPI()

            @app.post("/webhook")
            async def webhook(update: dict[str, Any]):
                telegram_update = Update(**update)
                await dp.feed_update(bot, telegram_update)
                return {"ok": True}

            # Set webhook
            await bot.set_webhook(url=settings.webhook_url)

            # Run with uvicorn server properly
            import uvicorn

            config = uvicorn.Config(app, host="0.0.0.0", port=8000, log_level="info")  # nosec B104
            server = uvicorn.Server(config)
            await server.serve()

        else:
            # Polling mode (development)
            logger.info("Starting polling mode")
            await bot.delete_webhook(drop_pending_updates=True)
            await dp.start_polling(bot)

    except Exception as e:
        logger.error(f"Bot failed: {e}")
        raise
    finally:
        await bot.session.close()
        await engine.dispose()
        logger.info("Bot stopped")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Bot stopped by user")
    except Exception as e:
        logging.error(f"Application failed: {e}")
        exit(1)
