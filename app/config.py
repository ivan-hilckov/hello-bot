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
    db_pool_size: int = Field(default=5, description="Database connection pool size")
    db_max_overflow: int = Field(default=10, description="Database max overflow connections")

    # Application settings
    environment: str = Field(
        default="development", description="Environment (development/production)"
    )
    debug: bool = Field(default=False, description="Debug mode")
    log_level: str = Field(default="INFO", description="Logging level")

    # Performance settings
    webhook_url: str | None = Field(default=None, description="Webhook URL for production")
    webhook_secret_token: str | None = Field(default=None, description="Webhook secret token")

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
