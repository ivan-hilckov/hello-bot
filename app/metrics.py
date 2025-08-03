"""
Prometheus metrics collection for Hello Bot.
"""

import time
from collections.abc import Callable

from fastapi import Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from starlette.middleware.base import BaseHTTPMiddleware

# Define metrics
REQUESTS_TOTAL = Counter(
    "bot_requests_total", "Total number of HTTP requests", ["method", "endpoint", "status_code"]
)

REQUEST_DURATION = Histogram(
    "bot_request_duration_seconds", "HTTP request duration in seconds", ["method", "endpoint"]
)

WEBHOOK_UPDATES_TOTAL = Counter(
    "bot_webhook_updates_total", "Total number of webhook updates processed", ["update_type"]
)

COMMANDS_TOTAL = Counter(
    "bot_commands_total", "Total number of bot commands processed", ["command"]
)

DATABASE_OPERATIONS = Counter(
    "bot_database_operations_total", "Total number of database operations", ["operation", "table"]
)

HEALTH_CHECK_STATUS = Counter(
    "bot_health_checks_total", "Total number of health checks", ["status", "component"]
)

# Active users gauge would require redis or memory store
# For now we'll track via counter
USER_INTERACTIONS = Counter(
    "bot_user_interactions_total",
    "Total user interactions",
    ["user_id"],  # Note: in production, consider hashing user_id for privacy
)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Middleware to collect HTTP request metrics."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and collect metrics."""
        start_time = time.time()

        # Extract endpoint info
        method = request.method
        endpoint = request.url.path

        try:
            response = await call_next(request)
            status_code = str(response.status_code)

            # Record metrics
            REQUESTS_TOTAL.labels(method=method, endpoint=endpoint, status_code=status_code).inc()

            REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(
                time.time() - start_time
            )

            return response

        except Exception as e:
            # Record error metrics
            REQUESTS_TOTAL.labels(method=method, endpoint=endpoint, status_code="500").inc()

            REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(
                time.time() - start_time
            )

            raise e


def get_metrics() -> str:
    """Get Prometheus metrics in text format."""
    return generate_latest()


def get_metrics_content_type() -> str:
    """Get content type for metrics endpoint."""
    return CONTENT_TYPE_LATEST


# Helper functions for tracking specific events
def track_command(command: str) -> None:
    """Track bot command usage."""
    COMMANDS_TOTAL.labels(command=command).inc()


def track_webhook_update(update_type: str) -> None:
    """Track webhook update processing."""
    WEBHOOK_UPDATES_TOTAL.labels(update_type=update_type).inc()


def track_database_operation(operation: str, table: str) -> None:
    """Track database operations."""
    DATABASE_OPERATIONS.labels(operation=operation, table=table).inc()


def track_health_check(status: str, component: str) -> None:
    """Track health check results."""
    HEALTH_CHECK_STATUS.labels(status=status, component=component).inc()


def track_user_interaction(user_id: int) -> None:
    """Track user interactions (consider privacy implications)."""
    # In production, consider hashing user_id for privacy
    hashed_id = str(hash(str(user_id)) % 10000)  # Simple hash for demo
    USER_INTERACTIONS.labels(user_id=hashed_id).inc()
