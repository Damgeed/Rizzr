"""Shared response and error types for the Rizzr API."""
from __future__ import annotations

from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ErrorDetail(BaseModel):
    code: str
    message: str


class APIResponse(BaseModel, Generic[T]):
    success: bool
    data: T | None = None
    error: ErrorDetail | None = None


class HealthData(BaseModel):
    status: str = "ok"
    service: str = "rizzr-api"
    version: str = "1.0.0"
    environment: str


class UsageData(BaseModel):
    remaining: int = Field(ge=0)
    window_seconds: int = Field(gt=0)
