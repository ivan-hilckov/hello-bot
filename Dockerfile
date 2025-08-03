# Optimized Dockerfile for Hello Bot using uv with enhanced caching
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS builder

# Install system dependencies for building
RUN apk add --no-cache curl gcc musl-dev

WORKDIR /app

# Copy dependency files ONLY for optimal caching
COPY pyproject.toml ./
# Copy uv.lock if it exists (optional for reproducible builds)
COPY uv.lock* ./

# Install dependencies with cache mounts for optimal performance
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=cache,target=/tmp/uv-cache \
  if [ -f "uv.lock" ]; then \
  uv sync --frozen --no-dev; \
  else \
  uv sync --no-dev; \
  fi

# === RUNTIME STAGE ===
FROM python:3.12-alpine AS runtime

# Install runtime dependencies only
RUN apk add --no-cache curl

# Create non-root user for security
RUN addgroup -g 1001 -S botuser && \
  adduser -u 1001 -S botuser -G botuser

WORKDIR /app

# Copy virtual environment from builder (cached layer)
COPY --from=builder --chown=botuser:botuser /app/.venv /app/.venv

# Make sure we use venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy dependency files first (rarely changes)
COPY --chown=botuser:botuser pyproject.toml ./
COPY --chown=botuser:botuser alembic.ini ./

# Copy alembic configuration (changes less frequently)
COPY --chown=botuser:botuser alembic/ ./alembic/

# Copy application code LAST (changes most frequently)
COPY --chown=botuser:botuser app/ ./app/

# Switch to non-root user
USER botuser

# Optimized health check for faster startup detection
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --start-interval=2s --retries=12 \
  CMD python -c "import asyncio; from app.config import settings; exit(0 if settings.bot_token else 1)"

# Labels for metadata
LABEL org.opencontainers.image.title="Hello Bot"
LABEL org.opencontainers.image.description="Minimal Telegram bot for deployment testing"
LABEL org.opencontainers.image.version="1.1.0"

# Start the bot (migrations run separately)
CMD ["python", "-m", "app.main"]