"""Rizzr — Rate Limiting Middleware

IP-based sliding window rate limiter.
Uses Redis if available, falls back to in-memory dict.
"""
import time
import json
from collections import defaultdict
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from config import get_settings


class InMemoryRateLimiter:
    """Fallback when Redis isn't available."""
    def __init__(self):
        self._store: dict[str, list[float]] = defaultdict(list)

    def check(self, key: str, limit: int, window: int) -> tuple[bool, int]:
        now = time.time()
        # Clean old entries
        self._store[key] = [t for t in self._store[key] if now - t < window]
        remaining = limit - len(self._store[key])
        if remaining <= 0:
            return False, 0
        self._store[key].append(now)
        return True, remaining - 1


class RedisRateLimiter:
    """Production rate limiter using Redis sliding window."""
    def __init__(self, redis_url: str):
        import redis
        self.r = redis.from_url(redis_url, decode_responses=True)

    def check(self, key: str, limit: int, window: int) -> tuple[bool, int]:
        now = time.time()
        pipe = self.r.pipeline()
        pipe.zremrangebyscore(key, 0, now - window)
        pipe.zadd(key, {str(now): now})
        pipe.zcard(key)
        pipe.expire(key, window)
        results = pipe.execute()
        count = results[2]
        remaining = limit - count
        if remaining < 0:
            return False, 0
        return True, remaining


def get_rate_limiter():
    settings = get_settings()
    if settings.redis_url:
        try:
            return RedisRateLimiter(settings.redis_url)
        except Exception:
            pass
    return InMemoryRateLimiter()


# Singleton
_limiter = None


def get_limiter():
    global _limiter
    if _limiter is None:
        _limiter = get_rate_limiter()
    return _limiter


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limit only /api/* endpoints (not health checks)."""
    async def dispatch(self, request: Request, call_next):
        # Skip non-API routes
        if not request.url.path.startswith("/api/"):
            return await call_next(request)
        if request.url.path in ("/api/usage",):
            return await call_next(request)

        settings = get_settings()
        client_ip = request.client.host if request.client else "unknown"
        limit_key = f"rizzr:rl:{client_ip}"

        limiter = get_limiter()
        allowed, remaining = limiter.check(
            limit_key,
            settings.rate_limit_free,
            settings.rate_window_seconds,
        )

        if not allowed:
            raise HTTPException(
                status_code=429,
                detail={
                    "error": "rate_limit_exceeded",
                    "message": "Daily free limit reached. Upgrade to Pro for unlimited replies.",
                    "reset_in_seconds": settings.rate_window_seconds,
                }
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        return response
