"""
Test configuration and fixtures.
"""

import asyncio
from collections.abc import AsyncGenerator

import pytest
from aiogram import Bot, types
from aiogram.types import User as TelegramUser
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.pool import StaticPool

from app.database.base import Base
from app.webhook import create_webhook_app


@pytest.fixture(scope="session")
def event_loop() -> asyncio.AbstractEventLoop:
    """Create event loop for the test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def test_engine() -> AsyncGenerator[AsyncEngine, None]:
    """Create test database engine with in-memory SQLite."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    # Cleanup
    await engine.dispose()


@pytest.fixture
async def test_session(test_engine: AsyncEngine) -> AsyncGenerator[AsyncSession, None]:
    """Create test database session."""
    async with AsyncSession(test_engine, expire_on_commit=False) as session:
        yield session
        await session.rollback()


@pytest.fixture
def mock_bot() -> Bot:
    """Create mock bot instance for testing."""
    return Bot("1234567890:MOCK_TOKEN_FOR_TESTING")


@pytest.fixture
def telegram_user() -> TelegramUser:
    """Create mock Telegram user for testing."""
    return TelegramUser(
        id=123456789,
        is_bot=False,
        first_name="Test",
        last_name="User",
        username="testuser",
        language_code="en",
    )


@pytest.fixture
def telegram_message(telegram_user: TelegramUser) -> types.Message:
    """Create mock Telegram message for testing."""
    return types.Message(
        message_id=1,
        date=1640995200,  # 2022-01-01 00:00:00 UTC
        chat=types.Chat(id=123456789, type="private"),
        from_user=telegram_user,
        text="/start",
    )


@pytest.fixture
async def test_client(mock_bot: Bot) -> AsyncGenerator[AsyncClient, None]:
    """Create test client for FastAPI webhook app."""
    from aiogram import Dispatcher, F, Router
    from aiogram.filters import Command

    from app.middlewares import DatabaseMiddleware

    # Create test-specific routers to avoid conflicts
    test_start_router = Router(name="test_start")
    test_common_router = Router(name="test_common")

    @test_start_router.message(Command("start"))
    async def test_start_handler(message: types.Message) -> None:
        await message.answer("Test response")

    @test_common_router.message(F.text)
    async def test_default_handler(message: types.Message) -> None:
        await message.answer("Test default response")

    # Create fresh dispatcher for testing
    dp = Dispatcher()
    dp.message.middleware(DatabaseMiddleware())
    dp.include_router(test_start_router)
    dp.include_router(test_common_router)

    app = create_webhook_app(mock_bot, dp)

    from httpx import ASGITransport

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest.fixture
def monkeypatch_session(test_session: AsyncSession, monkeypatch: pytest.MonkeyPatch) -> None:
    """Monkeypatch database session for testing."""

    async def mock_session() -> AsyncSession:
        return test_session

    monkeypatch.setattr("app.database.session.AsyncSessionLocal", mock_session)
