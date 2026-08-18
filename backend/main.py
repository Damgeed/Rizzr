"""Rizzr — FastAPI application entry point."""
from __future__ import annotations

import os

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.responses import JSONResponse

from config import get_settings
from middleware.rate_limit import RateLimitMiddleware
from middleware.security import setup_middleware
from routers import generate, transcribe, tts
from schemas import APIResponse, HealthData

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url=None,
)

setup_middleware(app)
app.add_middleware(RateLimitMiddleware)

if settings.is_production:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.allowed_hosts,
    )

app.include_router(transcribe.router)
app.include_router(generate.router)
app.include_router(tts.router)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": {
                "code": "validation_error",
                "message": "Request validation failed.",
            },
        },
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    detail = exc.detail if isinstance(exc.detail, dict) else {}
    code = str(detail.get("code") or "http_error")
    message = str(detail.get("message") or exc.detail or "Request failed.")
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "error": {"code": code, "message": message}},
    )


@app.exception_handler(RuntimeError)
async def runtime_exception_handler(request: Request, exc: RuntimeError):
    return JSONResponse(
        status_code=503,
        content={
            "success": False,
            "error": {
                "code": "service_not_configured",
                "message": str(exc) if settings.debug else "Service is not configured.",
            },
        },
    )


@app.get("/health", response_model=APIResponse[HealthData])
async def health():
    return APIResponse(
        success=True,
        data=HealthData(environment=settings.environment),
    )


@app.get("/")
async def root():
    return {
        "success": True,
        "data": {
            "service": "Rizzr API",
            "version": "1.0.0",
            "docs": "/docs" if settings.debug else "disabled",
            "endpoints": ["/health", "/api/transcribe", "/api/generate"],
        },
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
