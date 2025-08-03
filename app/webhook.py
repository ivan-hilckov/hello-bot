"""
Webhook server implementation using FastAPI.
"""

import time
from typing import Any

import structlog
from aiogram import Bot, Dispatcher
from aiogram.types import Update
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse, Response
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy import text

from app.config import settings
from app.database.session import AsyncSessionLocal
from app.metrics import (
    MetricsMiddleware,
    get_metrics,
    get_metrics_content_type,
    track_health_check,
    track_user_interaction,
    track_webhook_update,
)

logger = structlog.get_logger(__name__)


def create_webhook_app(bot: Bot, dp: Dispatcher) -> FastAPI:
    """Create FastAPI application for webhook handling."""
    app = FastAPI(
        title="Telegram Bot Webhook",
        description="Telegram Bot Webhook Server",
        version="1.1.0",
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None if settings.is_production else "/redoc",
    )

    # Rate limiter setup
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # Security middleware (production only) - disabled for now
    # if settings.is_production:
    #     app.add_middleware(TrustedHostMiddleware, allowed_hosts=["*"])

    # Performance middleware
    app.add_middleware(GZipMiddleware, minimum_size=1000)

    # Metrics middleware
    app.add_middleware(MetricsMiddleware)

    # Request logging middleware
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        """Log all HTTP requests with structured logging."""
        start_time = time.time()

        logger.info(
            "Request started",
            method=request.method,
            url=str(request.url),
            client_ip=request.client.host if request.client else "unknown",
            user_agent=request.headers.get("user-agent", "unknown"),
        )

        try:
            response = await call_next(request)
            process_time = round((time.time() - start_time) * 1000, 2)

            logger.info(
                "Request completed",
                method=request.method,
                url=str(request.url),
                status_code=response.status_code,
                process_time_ms=process_time,
                response_size=response.headers.get("content-length", "unknown"),
            )

            return response

        except Exception as e:
            process_time = round((time.time() - start_time) * 1000, 2)

            logger.error(
                "Request failed",
                method=request.method,
                url=str(request.url),
                process_time_ms=process_time,
                error=str(e),
                exc_info=True,
            )
            raise

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
            track_health_check("healthy", "database")
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            checks["database"] = f"unhealthy: {str(e)[:100]}"  # Limit error message length
            track_health_check("unhealthy", "database")

        # Bot API health check
        try:
            bot_info = await bot.get_me()
            checks["bot_api"] = "healthy"
            checks["bot_username"] = bot_info.username
            track_health_check("healthy", "bot_api")
        except Exception as e:
            logger.error(f"Bot API health check failed: {e}")
            checks["bot_api"] = f"unhealthy: {str(e)[:100]}"
            track_health_check("unhealthy", "bot_api")

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
            "version": "1.1.0",
            "environment": settings.environment,
        }

    @app.get("/metrics")
    async def metrics_endpoint() -> Response:
        """Prometheus metrics endpoint."""
        metrics_data = get_metrics()
        return Response(content=metrics_data, media_type=get_metrics_content_type())

    @app.post(settings.webhook_path)
    @limiter.limit(settings.rate_limit)
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

            # Track webhook update metrics
            update_type = "unknown"
            if update.message:
                update_type = "message"
                if update.message.from_user:
                    track_user_interaction(update.message.from_user.id)
            elif update.callback_query:
                update_type = "callback_query"
                if update.callback_query.from_user:
                    track_user_interaction(update.callback_query.from_user.id)
            elif update.inline_query:
                update_type = "inline_query"
                if update.inline_query.from_user:
                    track_user_interaction(update.inline_query.from_user.id)

            track_webhook_update(update_type)

            # Process update
            await dp.feed_update(bot, update)

            logger.debug("Webhook update processed successfully", update_type=update_type)
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
