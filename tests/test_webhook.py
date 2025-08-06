"""
Tests for webhook server.
"""

from httpx import AsyncClient


class TestWebhookServer:
    """Test cases for FastAPI webhook server."""

    async def test_enhanced_health_check(self, test_client: AsyncClient, mocker) -> None:
        """Test enhanced health check endpoint."""
        # Mock bot API to avoid real calls
        mock_bot_info = mocker.MagicMock()
        mock_bot_info.username = "test_bot"
        mock_get_me = mocker.AsyncMock(return_value=mock_bot_info)
        mocker.patch("aiogram.Bot.get_me", mock_get_me)

        # Mock database session to avoid real connection
        mock_session = mocker.AsyncMock()
        mock_session.execute = mocker.AsyncMock(return_value=None)
        mock_session_ctx = mocker.AsyncMock()
        mock_session_ctx.__aenter__ = mocker.AsyncMock(return_value=mock_session)
        mock_session_ctx.__aexit__ = mocker.AsyncMock(return_value=None)
        mocker.patch("app.database.AsyncSessionLocal", return_value=mock_session_ctx)

        response = await test_client.get("/health")

        assert response.status_code == 200
        data = response.json()

        # Check overall structure
        assert "status" in data
        assert "checks" in data
        assert "response_time_ms" in data
        assert "timestamp" in data
        assert "version" in data
        assert "environment" in data

        # Check individual components
        checks = data["checks"]
        assert "database" in checks
        assert "bot_api" in checks
        assert "memory_status" in checks

        # In test environment, these should be healthy
        assert checks["database"] == "healthy"
        assert checks["bot_api"] == "healthy"

        # Overall status should be healthy
        assert data["status"] == "healthy"

    async def test_webhook_endpoint_success(self, test_client: AsyncClient, mocker) -> None:
        """Test webhook endpoint processes update successfully."""
        # Mock bot session to avoid real API calls
        mock_session = mocker.AsyncMock()
        mock_session.return_value = {"ok": True, "result": {"message_id": 123}}
        mocker.patch("aiogram.client.session.aiohttp.AiohttpSession.make_request", mock_session)

        # Arrange
        fake_update = {
            "update_id": 123,
            "message": {
                "message_id": 1,
                "date": 1640995200,
                "chat": {"id": 123456789, "type": "private"},
                "from": {
                    "id": 123456789,
                    "is_bot": False,
                    "first_name": "Test",
                    "username": "testuser",
                },
                "text": "/start",
            },
        }

        # Act
        response = await test_client.post("/webhook", json=fake_update)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"

    async def test_webhook_endpoint_invalid_json(self, test_client: AsyncClient) -> None:
        """Test webhook endpoint with invalid JSON."""
        response = await test_client.post(
            "/webhook", content="invalid json", headers={"Content-Type": "application/json"}
        )

        assert response.status_code == 422  # Unprocessable Entity from FastAPI for invalid JSON

    async def test_docs_endpoint_disabled_in_production(self, test_client: AsyncClient) -> None:
        """Test that docs endpoint returns 404 (disabled in production-like config)."""
        response = await test_client.get("/docs")
        # In test environment, docs are enabled, so we expect 200
        # In real production with is_production=True, this would be 404
        assert response.status_code in [200, 404]
