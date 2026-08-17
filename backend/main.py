"""Rizzr — FastAPI Main Application

Entry point: mounts routers, middleware, health checks.
"""
import time
from fastapi import FastAPI
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from config import get_settings
from middleware.security import setup_middleware, SecurityHeadersMiddleware, RequestSizeLimitMiddleware
from middleware.rate_limit import RateLimitMiddleware
from routers import transcribe, generate, tts

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,  # disable docs in prod
    redoc_url=None,
)

# === Middleware (order matters: outermost first) ===
# 1. CORS + security headers + request size limit
setup_middleware(app)

# 2. Rate limiting (only on /api/* routes)
app.add_middleware(RateLimitMiddleware)

# 3. Trusted hosts (production lockdown)
if not settings.debug:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["rizzr.com", "www.rizzr.com", "*.rizzr.com", "*.up.railway.app"],
    )

# === Routers ===
app.include_router(transcribe.router)
app.include_router(generate.router)
app.include_router(tts.router)


# === Health checks ===
@app.get("/health")
async def health():
    return {"status": "ok", "service": "rizzr-api", "version": "1.0.0"}


@app.get("/")
async def root():
    return {
        "service": "Rizzr API",
        "version": "1.0.0",
        "docs": "/docs" if settings.debug else "disabled",
        "endpoints": ["/api/transcribe", "/api/generate", "/api/tts", "/api/usage"],
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(__import__("os").getenv("PORT", 8000)),
        reload=settings.debug,
    )
