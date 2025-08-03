"""
Redis caching implementation for Hello Bot.
"""

import pickle
from datetime import timedelta
from typing import Any

try:
    import redis.asyncio as redis

    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

import structlog

from app.config import settings

logger = structlog.get_logger(__name__)


class CacheService:
    """
    Redis cache service with fallback to in-memory cache.
    """

    def __init__(self):
        self._redis_client: redis.Redis | None = None
        self._memory_cache: dict[str, Any] = {}
        self._redis_available = False

    async def initialize(self) -> None:
        """Initialize Redis connection."""
        if not REDIS_AVAILABLE:
            logger.warning("Redis not available, using in-memory cache")
            return

        if not settings.redis_enabled:
            logger.info("Redis disabled in settings, using in-memory cache")
            return

        try:
            self._redis_client = redis.from_url(
                settings.redis_url,
                encoding="utf-8",
                decode_responses=False,  # We'll handle encoding ourselves
                socket_timeout=5,
                socket_connect_timeout=5,
                retry_on_timeout=True,
                health_check_interval=30,
            )

            # Test connection
            await self._redis_client.ping()
            self._redis_available = True
            logger.info("Redis connection established", url=settings.redis_url)

        except Exception as e:
            logger.error("Failed to connect to Redis", error=str(e))
            self._redis_available = False

    async def close(self) -> None:
        """Close Redis connection."""
        if self._redis_client:
            await self._redis_client.close()
            logger.info("Redis connection closed")

    async def get(self, key: str) -> Any | None:
        """
        Get value from cache.

        Args:
            key: Cache key

        Returns:
            Cached value or None if not found
        """
        if self._redis_available and self._redis_client:
            try:
                data = await self._redis_client.get(key)
                if data:
                    return pickle.loads(data)
                return None
            except Exception as e:
                logger.error("Redis get error", key=key, error=str(e))
                # Fall back to memory cache
                return self._memory_cache.get(key)
        else:
            return self._memory_cache.get(key)

    async def set(self, key: str, value: Any, ttl: int | timedelta | None = None) -> bool:
        """
        Set value in cache.

        Args:
            key: Cache key
            value: Value to cache
            ttl: Time to live (seconds or timedelta)

        Returns:
            True if successful, False otherwise
        """
        if self._redis_available and self._redis_client:
            try:
                serialized = pickle.dumps(value)
                if isinstance(ttl, timedelta):
                    ttl = int(ttl.total_seconds())

                await self._redis_client.set(key, serialized, ex=ttl)
                return True
            except Exception as e:
                logger.error("Redis set error", key=key, error=str(e))
                # Fall back to memory cache
                self._memory_cache[key] = value
                return False
        else:
            self._memory_cache[key] = value
            return True

    async def delete(self, key: str) -> bool:
        """
        Delete value from cache.

        Args:
            key: Cache key

        Returns:
            True if successful, False otherwise
        """
        if self._redis_available and self._redis_client:
            try:
                await self._redis_client.delete(key)
                return True
            except Exception as e:
                logger.error("Redis delete error", key=key, error=str(e))
                # Fall back to memory cache
                if key in self._memory_cache:
                    del self._memory_cache[key]
                return False
        else:
            if key in self._memory_cache:
                del self._memory_cache[key]
            return True

    async def exists(self, key: str) -> bool:
        """
        Check if key exists in cache.

        Args:
            key: Cache key

        Returns:
            True if key exists, False otherwise
        """
        if self._redis_available and self._redis_client:
            try:
                return bool(await self._redis_client.exists(key))
            except Exception as e:
                logger.error("Redis exists error", key=key, error=str(e))
                return key in self._memory_cache
        else:
            return key in self._memory_cache

    async def increment(self, key: str, amount: int = 1) -> int:
        """
        Increment counter in cache.

        Args:
            key: Cache key
            amount: Amount to increment

        Returns:
            New value after increment
        """
        if self._redis_available and self._redis_client:
            try:
                return await self._redis_client.incr(key, amount)
            except Exception as e:
                logger.error("Redis incr error", key=key, error=str(e))
                # Fall back to memory cache
                current = self._memory_cache.get(key, 0)
                new_value = current + amount
                self._memory_cache[key] = new_value
                return new_value
        else:
            current = self._memory_cache.get(key, 0)
            new_value = current + amount
            self._memory_cache[key] = new_value
            return new_value

    async def set_hash(self, key: str, field: str, value: Any) -> bool:
        """
        Set hash field in cache.

        Args:
            key: Hash key
            field: Field name
            value: Field value

        Returns:
            True if successful, False otherwise
        """
        if self._redis_available and self._redis_client:
            try:
                serialized = pickle.dumps(value)
                await self._redis_client.hset(key, field, serialized)
                return True
            except Exception as e:
                logger.error("Redis hset error", key=key, field=field, error=str(e))
                # Fall back to memory cache
                if key not in self._memory_cache:
                    self._memory_cache[key] = {}
                self._memory_cache[key][field] = value
                return False
        else:
            if key not in self._memory_cache:
                self._memory_cache[key] = {}
            self._memory_cache[key][field] = value
            return True

    async def get_hash(self, key: str, field: str) -> Any | None:
        """
        Get hash field from cache.

        Args:
            key: Hash key
            field: Field name

        Returns:
            Field value or None if not found
        """
        if self._redis_available and self._redis_client:
            try:
                data = await self._redis_client.hget(key, field)
                if data:
                    return pickle.loads(data)
                return None
            except Exception as e:
                logger.error("Redis hget error", key=key, field=field, error=str(e))
                # Fall back to memory cache
                return self._memory_cache.get(key, {}).get(field)
        else:
            return self._memory_cache.get(key, {}).get(field)

    def is_redis_available(self) -> bool:
        """Check if Redis is available and connected."""
        return self._redis_available


# Global cache service instance
cache_service = CacheService()


async def initialize_cache() -> None:
    """Initialize cache service."""
    await cache_service.initialize()


async def close_cache() -> None:
    """Close cache service."""
    await cache_service.close()


# Cache decorator for functions
def cached(ttl: int | timedelta = 300, key_prefix: str = ""):
    """
    Decorator to cache function results.

    Args:
        ttl: Time to live in seconds or timedelta
        key_prefix: Prefix for cache key

    Example:
        @cached(ttl=60, key_prefix="user")
        async def get_user_data(user_id: int):
            return expensive_computation(user_id)
    """

    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Generate cache key
            import hashlib

            key_data = f"{key_prefix}:{func.__name__}:{str(args)}:{str(kwargs)}"
            cache_key = hashlib.md5(key_data.encode()).hexdigest()

            # Try to get from cache
            cached_result = await cache_service.get(cache_key)
            if cached_result is not None:
                logger.debug("Cache hit", function=func.__name__, key=cache_key)
                return cached_result

            # Execute function and cache result
            result = await func(*args, **kwargs)
            await cache_service.set(cache_key, result, ttl)
            logger.debug("Cache miss, result cached", function=func.__name__, key=cache_key)

            return result

        return wrapper

    return decorator
