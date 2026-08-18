"""Rizzr — Backend Configuration."""
from __future__ import annotations

import os
from functools import lru_cache
from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings loaded from environment variables only."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Rizzr API"
    environment: Literal["development", "staging", "production"] = Field(default="production", alias="APP_ENV")
    debug: bool = Field(default=False, alias="DEBUG")

    allowed_origins: list[str] = Field(
        default_factory=lambda: [
            "https://rizzr.com",
            "https://www.rizzr.com",
            "https://damgeed.github.io",
            "http://localhost:8080",
            "http://localhost:3000",
        ]
    )
    allowed_hosts: list[str] = Field(
        default_factory=lambda: [
            "rizzr.com",
            "www.rizzr.com",
            "api.rizzr.com",
            "*.rizzr.com",
            "*.up.railway.app",
            "localhost",
            "127.0.0.1",
            "testserver",
        ]
    )

    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    openai_whisper_model: str = Field(default="whisper-1", alias="OPENAI_WHISPER_MODEL")

    llm_base_url: str = Field(default="https://ai.kaiweb.net/v1", alias="LLM_BASE_URL")
    llm_api_key: str = Field(default="", alias="LLM_API_KEY")
    llm_model: str = Field(default="glm-5.2", alias="LLM_MODEL")

    elevenlabs_api_key: str = Field(default="", alias="ELEVENLABS_API_KEY")
    elevenlabs_voice_id: str = Field(default="", alias="ELEVENLABS_VOICE_ID")
    elevenlabs_model: str = Field(default="eleven_multilingual_v2", alias="ELEVENLABS_MODEL")

    rate_limit_free: int = Field(default=30, alias="RATE_LIMIT_FREE")
    rate_limit_pro: int = Field(default=999_999, alias="RATE_LIMIT_PRO")
    rate_window_seconds: int = Field(default=86_400, alias="RATE_WINDOW_SECONDS")

    max_audio_size: int = Field(default=25 * 1024 * 1024, alias="MAX_AUDIO_SIZE")
    max_audio_duration: int = Field(default=120, alias="MAX_AUDIO_DURATION")
    allowed_mime_types: list[str] = [
        "audio/mp4",
        "audio/m4a",
        "audio/x-m4a",
        "audio/aac",
        "audio/mpeg",
        "audio/mp3",
        "audio/wav",
        "audio/webm",
        "audio/ogg",
    ]

    redis_url: str = Field(default="", alias="REDIS_URL")

    @field_validator("allowed_origins", "allowed_hosts", mode="before")
    @classmethod
    def parse_csv_list(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @property
    def is_production(self) -> bool:
        return self.environment == "production" and not self.debug

    def require_openai_key(self) -> None:
        if not self.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured")

    def require_llm_key(self) -> None:
        if not self.llm_api_key:
            raise RuntimeError("LLM_API_KEY is not configured")

    def require_elevenlabs_key(self) -> None:
        if not self.elevenlabs_api_key:
            raise RuntimeError("ELEVENLABS_API_KEY is not configured")


@lru_cache
def get_settings() -> Settings:
    return Settings()
