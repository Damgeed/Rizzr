"""Rizzr — Rate Limiting Middleware."""
from __future__ import annotations

import ipaddress
import time
from collections import defaultdict

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from config import get_settings


class InMemoryRateLimiter:
    """Single-process fallback when Redis is not configured."""

    def __init__(self) -> None:
        self._store: dict[str, list[float]] = defaultdict(list)

    def check(self, key: str, limit: int, window: int) -> tuple[bool, int]:
        now = time.time()
        self._store[key] = [timestamp for timestamp in self._store[key] if now - timestamp < window]
        remaining = limit - len(self._store[key])
        if remaining <= 0:
            return False, 0
        self._store[key].append(now)
        return True, remaining - 1


class RedisRateLimiter:
    """Redis-backed sliding-window limiter for production."""

    def __init__(self, redis_url: str) -> None:
        import redis

        self.redis = redis.from_url(redis_url, decode_responses=True)

    def check(self, key: str, limit: int, window: int) -> tuple[bool, int]:
        now = time.time()
        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(key, 0, now - window)
        pipe.zadd(key, {str(now): now})
        pipe.zcard(key)
        pipe.expire(key, window)
        results = pipe.execute()
        count = int(results[2])
        remaining = limit - count
        if remaining < 0:
            return False, 0
        return True, remaining


def resolve_client_ip(request: Request) -> str:
    cf_ip = request.headers.get("cf-connecting-ip")
    if cf_ip:
        return cf_ip

    forwarded_for = request.headers.get("x-forwarded-for", "")
    for raw_ip in forwarded_for.split(","):
        candidate = raw_ip.strip()
        if not candidate:
            continue
        try:
            parsed = ipaddress.ip_address(candidate)
        except ValueError:
            continue
        if parsed.is_global:
            return candidate

    return request.client.host if request.client else "unknown"


_limiter = None


def get_limiter():
    global _limiter
    if _limiter is not None:
        return _limiter

    settings = get_settings()
    if settings.redis_url:
        try:
            _limiter = RedisRateLimiter(settings.redis_url)
            return _limiter
        except Exception:
            pass

    _limiter = InMemoryRateLimiter()
    return _limiter


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate-limit mutation endpoints. Health checks stay public."""

    async def dispatch(self, request: Request, call_next):
        if not request.url.path.startswith("/api/") or request.method == "OPTIONS":
            return await call_next(request)

        settings = get_settings()
        client_ip = resolve_client_ip(request)
        limit_key = f"rizzr:rl:{client_ip}:{request.url.path}"
        allowed, remaining = get_limiter().check(limit_key, settings.rate_limit_free, settings.rate_window_seconds)

        if not allowed:
            return JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "error": {
                        "code": "rate_limit_exceeded",
                        "message": "Daily limit reached. Upgrade to Pro for unlimited replies.",
                    },
                },
                headers={"X-RateLimit-Remaining": "0"},
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        return response
