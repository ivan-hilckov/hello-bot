"""
Structured logging configuration using structlog.
"""

import logging
import sys
from typing import Any

import structlog
from structlog.stdlib import BoundLogger

from app.config import settings


def setup_structured_logging() -> BoundLogger:
    """
    Configure structured logging for the application.

    Returns:
        BoundLogger: Configured structured logger instance
    """
    # Configure processors based on environment
    if settings.is_production:
        # Production: JSON format for log aggregation
        processors = [
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer(),
        ]
    else:
        # Development: Human-readable format
        processors = [
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="%Y-%m-%d %H:%M:%S"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.dev.ConsoleRenderer(colors=True),
        ]

    # Configure structlog
    structlog.configure(
        processors=processors,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Configure standard library logging
    log_level = getattr(logging, settings.log_level.upper())

    # Create root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    # Remove existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Add structured handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(log_level)
    root_logger.addHandler(handler)

    # Set specific loggers levels for production
    if settings.is_production:
        logging.getLogger("aiogram").setLevel(logging.WARNING)
        logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
        logging.getLogger("uvicorn").setLevel(logging.INFO)
        logging.getLogger("fastapi").setLevel(logging.WARNING)

    return structlog.get_logger()


def log_user_interaction(
    logger: BoundLogger,
    event: str,
    user_id: int | None = None,
    username: str | None = None,
    command: str | None = None,
    **kwargs: Any,
) -> None:
    """
    Log user interaction with structured data.

    Args:
        logger: Structured logger instance
        event: Event description
        user_id: Telegram user ID
        username: Telegram username
        command: Bot command used
        **kwargs: Additional context data
    """
    context = {
        "event_type": "user_interaction",
        "user_id": user_id,
        "username": username,
        "command": command,
        **kwargs,
    }

    # Remove None values
    context = {k: v for k, v in context.items() if v is not None}

    logger.info(event, **context)


def log_system_event(
    logger: BoundLogger, event: str, component: str, status: str = "success", **kwargs: Any
) -> None:
    """
    Log system event with structured data.

    Args:
        logger: Structured logger instance
        event: Event description
        component: System component (database, bot_api, webhook, etc.)
        status: Event status (success, error, warning)
        **kwargs: Additional context data
    """
    context = {"event_type": "system_event", "component": component, "status": status, **kwargs}

    logger.info(event, **context)


def log_performance_metric(
    logger: BoundLogger, operation: str, duration_ms: float, **kwargs: Any
) -> None:
    """
    Log performance metric with structured data.

    Args:
        logger: Structured logger instance
        operation: Operation name
        duration_ms: Operation duration in milliseconds
        **kwargs: Additional context data
    """
    context = {
        "event_type": "performance_metric",
        "operation": operation,
        "duration_ms": duration_ms,
        **kwargs,
    }

    logger.info("Performance metric", **context)
