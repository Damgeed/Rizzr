"""Rizzr — Whisper Transcription Router

POST /api/transcribe
- Validates audio file (MIME + size + duration)
- Forwards to OpenAI Whisper API
- Returns transcript + detected language
- Audio is never persisted to disk
"""
import io
import json
import httpx
from fastapi import APIRouter, UploadFile, File, HTTPException, Request
from pydantic import BaseModel

from config import get_settings

router = APIRouter()


class TranscribeResponse(BaseModel):
    transcript: str
    language: str
    duration: float


@router.post("/api/transcribe", response_model=TranscribeResponse)
async def transcribe(request: Request, file: UploadFile = File(...)):
    settings = get_settings()

    # === Validation ===
    # 1. MIME type check
    if file.content_type not in settings.allowed_mime_types:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported audio format: {file.content_type}. Allowed: {', '.join(settings.allowed_mime_types)}"
        )

    # 2. Read audio into memory (not disk)
    audio_bytes = await file.read()

    # 3. Size check
    if len(audio_bytes) > settings.max_audio_size:
        raise HTTPException(
            status_code=413,
            detail=f"Audio too large. Max {settings.max_audio_size // (1024*1024)}MB."
        )

    if len(audio_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty audio file")

    # === Forward to Whisper API ===
    whisper_url = "https://api.openai.com/v1/audio/transcriptions"
    headers = {
        "Authorization": f"Bearer {settings.openai_api_key}",
    }
    files = {
        "file": (file.filename or "audio.webm", io.BytesIO(audio_bytes), file.content_type),
        "model": (None, settings.openai_whisper_model),
        "response_format": (None, "verbose_json"),
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(whisper_url, headers=headers, files=files)
            resp.raise_for_status()
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Transcription timed out")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"Whisper API error: {e.response.status_code}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")

    data = resp.json()

    # === Cleanup: audio_bytes is garbage-collected when function returns ===
    # No disk write, no persistence, no storage.

    return TranscribeResponse(
        transcript=data.get("text", "").strip(),
        language=data.get("language", "unknown"),
        duration=data.get("duration", 0.0),
    )
