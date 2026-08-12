"""Rizzr — TTS (Text-to-Speech) Router

POST /api/tts
- Receives reply text
- Calls ElevenLabs API for voice synthesis
- Returns audio blob (MP3)
- Audio URL is temporary (client-side blob URL)
"""
import httpx
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from config import get_settings

router = APIRouter()


class TTSRequest(BaseModel):
    text: str
    voice_id: str = "default"


@router.post("/api/tts")
async def tts(body: TTSRequest):
    settings = get_settings()

    if not body.text.strip():
        raise HTTPException(status_code=400, detail="Empty text")

    # Text length limit (prevent abuse)
    if len(body.text) > 500:
        raise HTTPException(status_code=400, detail="Text too long (max 500 chars)")

    voice_id = body.voice_id if body.voice_id != "default" else settings.elevenlabs_voice_id

    if not voice_id:
        raise HTTPException(status_code=500, detail="TTS not configured")

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "xi-api-key": settings.elevenlabs_api_key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    }
    payload = {
        "text": body.text,
        "model_id": settings.elevenlabs_model,
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75,
            "style": 0.0,
            "use_speaker_boost": True,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(url, headers=headers, json=payload)
            resp.raise_for_status()
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="TTS timed out")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"ElevenLabs error: {e.response.status_code}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS failed: {str(e)}")

    return Response(
        content=resp.content,
        media_type="audio/mpeg",
        headers={
            "Cache-Control": "no-store",
            "X-TTS-Provider": "elevenlabs",
        }
    )
