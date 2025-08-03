"""
Main application entry point with production optimizations.
"""

import asyncio
import logging
import signal
import sys
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

# Performance optimization: use uvloop on production Linux systems
try:
    import uvloop

    if sys.platform != "win32":
        asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
except ImportError:
    # uvloop not available, use default event loop
    pass

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode

from app.config import settings
from app.database.session import create_tables, engine
from app.handlers import register_common_handlers, register_start_handlers
from app.middlewares import DatabaseMiddleware


# Configure logging
def setup_logging() -> None:
    """Configure logging for the application."""
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Configure root logger
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format=log_format,
        handlers=[
            logging.StreamHandler(sys.stdout),
        ],
    )

    # Set specific loggers
    if not settings.debug:
        # Reduce noise in production
        logging.getLogger("aiogram").setLevel(logging.WARNING)
        logging.getLogger("sqlalchemy").setLevel(logging.WARNING)


@asynccontextmanager
async def lifespan() -> AsyncGenerator[None, None]:
    """Application lifespan context manager."""
    logger = logging.getLogger(__name__)

    try:
        # Startup
        logger.info("Starting Hello Bot application")
        logger.info(f"Environment: {settings.environment}")
        logger.info(f"Debug mode: {settings.debug}")

        # Create database tables
        try:
            await create_tables()
            logger.info("Database tables created/verified")
        except Exception as e:
            logger.error(f"Failed to create database tables: {e}")
            raise

        yield

    finally:
        # Shutdown
        logger.info("Shutting down Hello Bot application")

        # Close database engine
        await engine.dispose()
        logger.info("Database connections closed")


def create_bot() -> Bot:
    """Create and configure bot instance."""
    if not settings.bot_token:
        raise ValueError("BOT_TOKEN is required but not provided")

    # Create bot with default properties
    bot = Bot(
        token=settings.bot_token,
        default=DefaultBotProperties(
            parse_mode=ParseMode.HTML,
        ),
    )

    return bot


def create_dispatcher() -> Dispatcher:
    """Create and configure dispatcher."""
    dp = Dispatcher()

    # Add middlewares
    dp.message.middleware(DatabaseMiddleware())

    # Register handlers
    register_start_handlers(dp)
    register_common_handlers(dp)

    return dp


async def main() -> None:
    """Main application function."""
    # Setup logging
    setup_logging()
    logger = logging.getLogger(__name__)

    async with lifespan():
        # Create bot and dispatcher
        bot = create_bot()
        dp = create_dispatcher()

        # Setup graceful shutdown
        shutdown_event = asyncio.Event()

        def signal_handler(signum, frame):
            logger.info(f"Received signal {signum}, initiating shutdown...")
            shutdown_event.set()

        # Register signal handlers for graceful shutdown
        if sys.platform != "win32":
            signal.signal(signal.SIGTERM, signal_handler)
            signal.signal(signal.SIGINT, signal_handler)

        try:
            logger.info("Bot is starting...")

            if settings.is_production and settings.webhook_url:
                # Production webhook mode
                logger.info(f"Starting in webhook mode: {settings.webhook_url}")
                await bot.set_webhook(
                    url=settings.webhook_url,
                    secret_token=settings.webhook_secret_token,
                )
                # Note: In real webhook mode, you'd start a web server here
                # For now, we'll still use polling even in production
                await dp.start_polling(bot, handle_signals=False)
            else:
                # Development polling mode
                logger.info("Starting in polling mode")

                # Delete webhook if set
                await bot.delete_webhook(drop_pending_updates=True)

                # Start polling
                polling_task = asyncio.create_task(dp.start_polling(bot, handle_signals=False))

                # Wait for shutdown signal
                await shutdown_event.wait()

                # Cancel polling
                polling_task.cancel()
                try:
                    await polling_task
                except asyncio.CancelledError:
                    pass

        except Exception as e:
            logger.error(f"Bot failed to start: {e}", exc_info=True)
            raise
        finally:
            # Cleanup
            await bot.session.close()
            logger.info("Bot session closed")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        logging.error(f"Application failed: {e}", exc_info=True)
        sys.exit(1)
