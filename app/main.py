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

import uvicorn
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode

from app.config import settings
from app.database.session import create_tables, engine
from app.handlers import common_router, start_router
from app.logging import log_system_event, setup_structured_logging
from app.middlewares import DatabaseMiddleware
from app.webhook import create_webhook_app


@asynccontextmanager
async def lifespan() -> AsyncGenerator[None, None]:
    """Application lifespan context manager."""
    import structlog

    logger = structlog.get_logger(__name__)

    try:
        # Startup
        log_system_event(
            logger,
            "Starting Hello Bot application",
            component="main",
            environment=settings.environment,
            debug_mode=settings.debug,
            version="1.0.0",
        )

        # Create database tables
        try:
            await create_tables()
            log_system_event(
                logger, "Database tables created/verified", component="database", status="success"
            )
        except Exception as e:
            log_system_event(
                logger,
                "Failed to create database tables",
                component="database",
                status="error",
                error=str(e),
            )
            raise

        yield

    finally:
        # Shutdown
        log_system_event(
            logger, "Shutting down Hello Bot application", component="main", status="shutdown"
        )

        # Close database engine
        await engine.dispose()
        log_system_event(
            logger, "Database connections closed", component="database", status="shutdown"
        )


def create_bot() -> Bot:
    """Create and configure bot instance."""
    if not settings.bot_token:
        raise ValueError("BOT_TOKEN is required but not provided")

    # Create bot with default properties
    bot = Bot(
        token=settings.bot_token,
        default=DefaultBotProperties(
            parse_mode=ParseMode.MARKDOWN,
        ),
    )

    return bot


def create_dispatcher() -> Dispatcher:
    """Create and configure dispatcher."""
    dp = Dispatcher()

    # Add middlewares
    dp.message.middleware(DatabaseMiddleware())

    # Include routers (modern approach)
    dp.include_router(start_router)
    dp.include_router(common_router)

    return dp


async def main() -> None:
    """Main application function."""
    # Setup structured logging
    logger = setup_structured_logging()

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

                # Set webhook
                await bot.set_webhook(
                    url=settings.webhook_url,
                    secret_token=settings.webhook_secret_token,
                )
                logger.info("Webhook set successfully")

                # Create FastAPI app for webhook handling
                app = create_webhook_app(bot, dp)

                # Configure uvicorn
                config = uvicorn.Config(
                    app=app,
                    host=settings.webhook_host,
                    port=settings.webhook_port,
                    log_level="info" if settings.debug else "warning",
                    access_log=settings.debug,
                )

                # Start webhook server
                server = uvicorn.Server(config)
                logger.info(
                    f"Starting webhook server on {settings.webhook_host}:{settings.webhook_port}"
                )

                # Run server until shutdown signal
                server_task = asyncio.create_task(server.serve())
                await shutdown_event.wait()

                # Shutdown server
                server.should_exit = True
                await server_task

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
