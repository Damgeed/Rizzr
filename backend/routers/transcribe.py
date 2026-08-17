"""Rizzr — Transcription endpoint."""
from __future__ import annotations

import io

import httpx
from fastapi import APIRouter, File, HTTPException, UploadFile, status
from pydantic import BaseModel, Field

from config import get_settings
from schemas import APIResponse

router = APIRouter(prefix="/api", tags=["transcription"])


class TranscribeData(BaseModel):
    transcript: str = Field(min_length=1)
    language: str = "unknown"
    duration: float = Field(ge=0)


@router.post("/transcribe", response_model=APIResponse[TranscribeData])
async def transcribe(file: UploadFile = File(...)):
    settings = get_settings()
    settings.require_openai_key()

    if file.content_type not in settings.allowed_mime_types:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail={"code": "unsupported_audio_type", "message": "Unsupported audio format."},
        )

    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail={"code": "empty_audio", "message": "Audio file is empty."})
    if len(audio_bytes) > settings.max_audio_size:
        raise HTTPException(status_code=413, detail={"code": "audio_too_large", "message": "Audio file is too large."})

    files = {
        "file": (file.filename or "voice-note.m4a", io.BytesIO(audio_bytes), file.content_type),
        "model": (None, settings.openai_whisper_model),
        "response_format": (None, "verbose_json"),
    }
    headers = {"Authorization": f"Bearer {settings.openai_api_key}"}

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post("https://api.openai.com/v1/audio/transcriptions", headers=headers, files=files)
            response.raise_for_status()
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail={"code": "transcription_timeout", "message": "Transcription timed out."}) from exc
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=502,
            detail={"code": "transcription_provider_error", "message": f"Transcription provider failed with status {exc.response.status_code}."},
        ) from exc
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail={"code": "transcription_request_failed", "message": "Transcription request failed."}) from exc

    provider_data = response.json()
    transcript_text = str(provider_data.get("text", "")).strip()
    if not transcript_text:
        raise HTTPException(status_code=422, detail={"code": "empty_transcript", "message": "No speech was detected."})

    return APIResponse(
        success=True,
        data=TranscribeData(
            transcript=transcript_text,
            language=provider_data.get("language") or "unknown",
            duration=float(provider_data.get("duration") or 0),
        ),
    )
