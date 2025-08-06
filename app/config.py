"""
Simple application configuration.
"""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=False, extra="ignore"
    )

    # Required settings
    bot_token: str = Field(default="", description="Telegram Bot Token from BotFather")
    database_url: str = Field(
        default="postgresql+asyncpg://hello_user:password@localhost:5432/hello_bot",
        description="Database connection URL",
    )

    # Environment settings
    environment: str = Field(default="development", description="Environment")
    debug: bool = Field(default=False, description="Debug mode")

    # Optional webhook for production
    webhook_url: str | None = Field(default=None, description="Webhook URL for production")

    # Project settings
    project_name: str = Field(
        default="Hello Bot", description="Project name for greetings and display"
    )


# Global settings instance
settings = Settings()
