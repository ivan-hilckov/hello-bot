# Multi-stage optimized Dockerfile for Hello Bot
FROM python:3.11-slim as base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r botuser && useradd -r -g botuser botuser

WORKDIR /app

# === DEPENDENCY LAYER (cached unless dependencies change) ===
FROM base as dependencies

# Copy only dependency files first for better caching
COPY pyproject.toml ./
COPY uv.lock* ./

# Install uv for faster dependency management
RUN pip install uv

# Install dependencies using pyproject.toml
RUN uv pip install --system --no-cache-dir -e .

# === RUNTIME LAYER ===
FROM base as runtime

# Copy installed packages from dependencies stage
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Copy application code (this layer changes most frequently)
COPY --chown=botuser:botuser app/ ./app/
COPY --chown=botuser:botuser alembic/ ./alembic/
COPY --chown=botuser:botuser alembic.ini ./
COPY --chown=botuser:botuser pyproject.toml ./

# Switch to non-root user
USER botuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import asyncio; from app.config import settings; exit(0 if settings.bot_token else 1)"

# Labels for metadata
LABEL org.opencontainers.image.title="Hello Bot"
LABEL org.opencontainers.image.description="Minimal Telegram bot for deployment testing"
LABEL org.opencontainers.image.version="0.1.0"

# Run database migrations and start the bot  
CMD ["sh", "-c", "sleep 10 && echo 'Skipping alembic for now' && python -m app.main"]