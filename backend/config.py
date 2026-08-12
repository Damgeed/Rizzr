"""Rizzr — Backend Configuration"""
import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Rizzr API"
    debug: bool = os.getenv("DEBUG", "false").lower() == "true"

    # CORS — lock to production domains
    allowed_origins: list[str] = [
        "https://rizzr.com",
        "https://www.rizzr.com",
        "https://damgeed.github.io",  # GitHub Pages (temporary)
        "http://localhost:8080",       # dev
        "http://localhost:3000",
    ]

    # API Keys (server-side only, never exposed)
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    openai_whisper_model: str = "whisper-1"

    # LLM (kaiweb gateway — GLM-5.2)
    llm_base_url: str = os.getenv("LLM_BASE_URL", "https://ai.kaiweb.net/v1")
    llm_api_key: str = os.getenv("LLM_API_KEY", "")
    llm_model: str = os.getenv("LLM_MODEL", "glm-5.2")

    # ElevenLabs TTS
    elevenlabs_api_key: str = os.getenv("ELEVENLABS_API_KEY", "")
    elevenlabs_voice_id: str = os.getenv("ELEVENLABS_VOICE_ID", "")
    elevenlabs_model: str = "eleven_multilingual_v2"

    # Stripe
    stripe_secret_key: str = os.getenv("STRIPE_SECRET_KEY", "")
    stripe_webhook_secret: str = os.getenv("STRIPE_WEBHOOK_SECRET", "")
    stripe_price_id: str = os.getenv("STRIPE_PRICE_ID", "")

    # Rate limiting
    rate_limit_free: int = 3          # 3 requests per day for free tier
    rate_limit_pro: int = 999999      # effectively unlimited
    rate_window_seconds: int = 86400 # 24 hours

    # Audio constraints
    max_audio_size: int = 25 * 1024 * 1024  # 25MB (Whisper limit)
    max_audio_duration: int = 300           # 5 minutes
    allowed_mime_types: list[str] = [
        "audio/webm", "audio/wav", "audio/m4a",
        "audio/mp3", "audio/mpeg", "audio/ogg",
        "audio/mp4", "audio/aac",
    ]

    # Redis (for rate limiting — optional, falls back to in-memory)
    redis_url: str = os.getenv("REDIS_URL", "")


@lru_cache
def get_settings() -> Settings:
    return Settings()
