"""
Webhook server implementation using FastAPI.
"""

import logging
from typing import Any

from aiogram import Bot, Dispatcher
from aiogram.types import Update
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from app.config import settings

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

    @app.get("/health")
    async def health_check() -> dict[str, str]:
        """Health check endpoint."""
        return {"status": "ok", "bot": "healthy"}

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

            # Get request body
            body = await request.body()

            # Parse update
            try:
                update_data = await request.json()
                update = Update.model_validate(update_data)
            except Exception as e:
                logger.error(f"Failed to parse update: {e}")
                raise HTTPException(status_code=400, detail="Invalid update format")

            # Process update
            await dp.feed_update(bot, update)

            logger.debug("Webhook update processed successfully")
            return {"status": "ok"}

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Webhook processing error: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Internal server error")

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        """Global exception handler."""
        logger.error(f"Unhandled webhook error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500, content={"status": "error", "message": "Internal server error"}
        )

    return app
