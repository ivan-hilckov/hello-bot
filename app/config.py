"""
Application configuration using pydantic-settings.
"""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=False, extra="ignore"
    )

    # Bot configuration
    bot_token: str = Field(..., description="Telegram Bot Token from BotFather")

    # Database configuration
    database_url: str = Field(
        default="postgresql+asyncpg://hello_user:password@localhost:5432/hello_bot",
        description="Database connection URL",
    )
    # Optimized for 2GB VPS (reduced from defaults)
    db_pool_size: int = Field(default=3, description="Database connection pool size")
    db_max_overflow: int = Field(default=5, description="Database max overflow connections")

    # Application settings
    environment: str = Field(
        default="development", description="Environment (development/production)"
    )
    debug: bool = Field(default=False, description="Debug mode")
    log_level: str = Field(default="INFO", description="Logging level")

    # Webhook settings
    webhook_url: str | None = Field(default=None, description="Webhook URL for production")
    webhook_secret_token: str | None = Field(default=None, description="Webhook secret token")
    webhook_path: str = Field(default="/webhook", description="Webhook endpoint path")
    webhook_host: str = Field(default="0.0.0.0", description="Webhook server host")
    webhook_port: int = Field(default=8000, description="Webhook server port")

    # Security settings
    rate_limit: str = Field(default="100/minute", description="Rate limit for webhook endpoint")

    # Redis settings (for caching and metrics)
    redis_url: str = Field(default="redis://localhost:6379/0", description="Redis connection URL")
    redis_enabled: bool = Field(default=False, description="Enable Redis caching")

    # Performance settings
    db_pool_timeout: int = Field(default=30, description="Database pool timeout")
    db_pool_recycle: int = Field(default=3600, description="Database pool recycle time")

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() == "production"

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() == "development"


# Global settings instance
settings = Settings()
