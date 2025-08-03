"""
Webhook server implementation using FastAPI.
"""

import logging
import time
from typing import Any

from aiogram import Bot, Dispatcher
from aiogram.types import Update
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.config import settings
from app.database.session import AsyncSessionLocal

logger = logging.getLogger(__name__)


def create_webhook_app(bot: Bot, dp: Dispatcher) -> FastAPI:
    """Create FastAPI application for webhook handling."""
    app = FastAPI(
        title="Hello Bot Webhook",
        description="Telegram Bot Webhook Server",
        version="1.0.0",
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None if settings.is_production else "/redoc",
    )

    @app.get("/health", response_model=None)
    async def enhanced_health_check() -> dict[str, Any]:
        """
        Enhanced health check endpoint with database and bot API validation.

        Returns:
            dict: Health status with individual component checks
        """
        checks = {}
        start_time = time.time()

        # Database health check
        try:
            async with AsyncSessionLocal() as session:
                await session.execute(text("SELECT 1"))
            checks["database"] = "healthy"
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            checks["database"] = f"unhealthy: {str(e)[:100]}"  # Limit error message length

        # Bot API health check
        try:
            bot_info = await bot.get_me()
            checks["bot_api"] = "healthy"
            checks["bot_username"] = bot_info.username
        except Exception as e:
            logger.error(f"Bot API health check failed: {e}")
            checks["bot_api"] = f"unhealthy: {str(e)[:100]}"

        # Memory usage check (if psutil available)
        try:
            import psutil  # noqa: F401

            memory = psutil.virtual_memory()
            checks["memory_usage"] = f"{memory.percent}%"
            if memory.percent > 90:
                checks["memory_status"] = "warning: high usage"
            else:
                checks["memory_status"] = "healthy"
        except ImportError:
            # psutil not available in base dependencies
            checks["memory_status"] = "not_monitored"

        # Overall status determination
        critical_checks = ["database", "bot_api"]
        overall_status = (
            "healthy"
            if all(
                checks.get(check, "unhealthy").startswith("healthy") for check in critical_checks
            )
            else "unhealthy"
        )

        response_time = round((time.time() - start_time) * 1000, 2)  # milliseconds

        return {
            "status": overall_status,
            "checks": checks,
            "response_time_ms": response_time,
            "timestamp": time.time(),
            "version": "1.0.0",
            "environment": settings.environment,
        }

    @app.post(settings.webhook_path)
    async def webhook_handler(request: Request) -> dict[str, str]:
        """Handle incoming webhook requests from Telegram."""
        try:
            # Verify secret token if configured
            if settings.webhook_secret_token:
                secret_token = request.headers.get("X-Telegram-Bot-Api-Secret-Token")
                if secret_token != settings.webhook_secret_token:
                    logger.warning("Invalid webhook secret token")
                    raise HTTPException(status_code=401, detail="Unauthorized")

            # Parse update
            try:
                update_data = await request.json()
                update = Update.model_validate(update_data)
            except Exception as e:
                logger.error(f"Failed to parse update: {e}")
                raise HTTPException(status_code=400, detail="Invalid update format") from e

            # Process update
            await dp.feed_update(bot, update)

            logger.debug("Webhook update processed successfully")
            return {"status": "ok"}

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Webhook processing error: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Internal server error") from e

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        """Global exception handler."""
        logger.error(f"Unhandled webhook error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500, content={"status": "error", "message": "Internal server error"}
        )

    return app
