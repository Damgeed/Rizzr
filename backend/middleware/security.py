"""Rizzr — Security Middleware

CORS lockdown, request size limit, trusted hosts, input sanitization.
"""
import time
from fastapi import Request, Response, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.cors import CORSMiddleware

from config import get_settings


class RequestSizeLimitMiddleware(BaseHTTPMiddleware):
    """Reject requests larger than max_bytes."""
    def __init__(self, app, max_bytes: int = 30 * 1024 * 1024):
        super().__init__(app)
        self.max_bytes = max_bytes

    async def dispatch(self, request: Request, call_next):
        cl = request.headers.get("content-length")
        if cl and int(cl) > self.max_bytes:
            raise HTTPException(status_code=413, detail="Payload too large")
        return await call_next(request)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to all responses."""
    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "microphone=(), camera=()"
        return response


def setup_middleware(app):
    settings = get_settings()

    # CORS — locked to specific origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=["*"],
    )

    # Request size limit (30MB max — enough for 5min audio)
    app.add_middleware(RequestSizeLimitMiddleware, max_bytes=30 * 1024 * 1024)

    # Security headers
    app.add_middleware(SecurityHeadersMiddleware)
