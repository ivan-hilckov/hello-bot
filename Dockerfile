# Production-ready Docker image for Hello Bot
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r botuser && useradd -r -g botuser botuser

WORKDIR /app

# Copy application code
COPY --chown=botuser:botuser app/ ./app/
COPY --chown=botuser:botuser alembic/ ./alembic/
COPY --chown=botuser:botuser alembic.ini ./
COPY --chown=botuser:botuser pyproject.toml ./
COPY --chown=botuser:botuser uv.lock* ./

# Install dependencies directly with pip
RUN pip install aiogram python-dotenv pydantic pydantic-settings sqlalchemy[asyncio] asyncpg alembic

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