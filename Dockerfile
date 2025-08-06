# Simple Dockerfile for Hello Bot
FROM python:3.12-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev

# Install uv for fast dependency management
RUN pip install uv

WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies
RUN uv venv && \
    . .venv/bin/activate && \
    uv pip install --no-cache-dir \
    aiogram \
    sqlalchemy[asyncio] \
    asyncpg \
    pydantic-settings \
    fastapi \
    uvicorn

# === RUNTIME STAGE ===
FROM python:3.12-alpine AS runtime

# Create non-root user
RUN addgroup -g 1001 -S botuser && \
  adduser -u 1001 -S botuser -G botuser

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder --chown=botuser:botuser /app/.venv /app/.venv

# Make sure we use venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY --chown=botuser:botuser app/ ./app/

# Switch to non-root user
USER botuser

# Simple health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "from app.config import settings; exit(0 if settings.bot_token else 1)"

# Labels
LABEL org.opencontainers.image.title="Hello Bot"
LABEL org.opencontainers.image.description="Simple Telegram bot with PostgreSQL"
LABEL org.opencontainers.image.version="2.0.0"

# Start the bot
CMD ["python", "-m", "app.main"]
