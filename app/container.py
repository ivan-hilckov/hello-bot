"""
Dependency injection container for Telegram Bot.
Simple DI implementation without external dependencies.
"""

from collections.abc import Callable
from functools import wraps
from typing import Any, TypeVar

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.user import UserService

T = TypeVar("T")

logger = structlog.get_logger(__name__)


class Container:
    """Simple dependency injection container."""

    def __init__(self):
        self._services: dict[type, Callable[..., Any]] = {}
        self._singletons: dict[type, Any] = {}
        self._setup_services()

    def _setup_services(self) -> None:
        """Setup service registrations."""
        # Register services
        self.register(UserService, self._create_user_service)

    def register(self, service_type: type[T], factory: Callable[..., T]) -> None:
        """Register a service with its factory function."""
        self._services[service_type] = factory
        logger.debug("Registered service", service_type=service_type.__name__)

    def register_singleton(self, service_type: type[T], instance: T) -> None:
        """Register a singleton instance."""
        self._singletons[service_type] = instance
        logger.debug("Registered singleton", service_type=service_type.__name__)

    async def get(self, service_type: type[T], session: AsyncSession) -> T:
        """
        Get service instance with dependency injection.

        Args:
            service_type: Type of service to create
            session: Database session to inject

        Returns:
            Service instance
        """
        # Check singletons first
        if service_type in self._singletons:
            return self._singletons[service_type]

        # Create service instance
        if service_type in self._services:
            factory = self._services[service_type]
            return await factory(session)

        raise ValueError(f"Service {service_type.__name__} not registered")

    def get_sync(self, service_type: type[T]) -> T:
        """Get singleton service (sync version)."""
        if service_type in self._singletons:
            return self._singletons[service_type]

        raise ValueError(f"Singleton {service_type.__name__} not registered")

    async def _create_user_service(self, session: AsyncSession) -> UserService:
        """Factory for UserService."""
        return UserService(session)


# Global container instance
container = Container()


def inject_services(*service_types: type):
    """
    Decorator to inject services into handler functions.

    Args:
        *service_types: Types of services to inject

    Example:
        @inject_services(UserService)
        async def handler(message: Message, user_service: UserService, session: AsyncSession):
            user = await user_service.get_or_create_user(message.from_user)
    """

    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract session from kwargs (injected by middleware)
            session = kwargs.get("session")
            if not session:
                raise ValueError(
                    "Session not found in kwargs. Ensure DatabaseMiddleware is active."
                )

            # Inject requested services
            for service_type in service_types:
                service_instance = await container.get(service_type, session)
                # Add service to kwargs using lowercase service name
                service_name = service_type.__name__.lower().replace("service", "")
                kwargs[f"{service_name}_service"] = service_instance

            return await func(*args, **kwargs)

        return wrapper

    return decorator


class ServiceProvider:
    """Service provider for manual service resolution."""

    def __init__(self, session: AsyncSession):
        self.session = session
        self._container = container

    async def get(self, service_type: type[T]) -> T:
        """Get service instance."""
        return await self._container.get(service_type, self.session)

    async def get_user_service(self) -> UserService:
        """Get UserService instance."""
        return await self.get(UserService)


def service_provider(session: AsyncSession) -> ServiceProvider:
    """Create service provider for the given session."""
    return ServiceProvider(session)


# Health check service registration
class HealthService:
    """Simple health check service."""

    def __init__(self):
        self.status = "healthy"

    def get_status(self) -> str:
        """Get current health status."""
        return self.status

    def set_status(self, status: str) -> None:
        """Set health status."""
        self.status = status


# Register health service as singleton
container.register_singleton(HealthService, HealthService())
