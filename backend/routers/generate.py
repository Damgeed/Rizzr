"""Rizzr — Reply generation endpoint."""
from __future__ import annotations

import json

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from config import get_settings
from schemas import APIResponse
from services.llm_client import LLMClientError, generate_chat_completion

router = APIRouter(prefix="/api", tags=["replies"])

EXPECTED_STYLES = ["flirty", "witty", "sweet"]


class GenerateRequest(BaseModel):
    transcript: str = Field(min_length=1, max_length=5_000)
    styles: list[str] = Field(default_factory=lambda: EXPECTED_STYLES.copy())


class ReplySuggestion(BaseModel):
    style: str
    text: str = Field(min_length=1, max_length=500)


class GenerateData(BaseModel):
    replies: list[ReplySuggestion] = Field(min_length=3, max_length=3)


SYSTEM_PROMPT = """You are Rizzr's Finesse reply engine.
Return strict JSON only: {"replies":[{"style":"flirty","text":"..."},{"style":"witty","text":"..."},{"style":"sweet","text":"..."}]}.
Rules:
- Generate exactly three replies.
- Styles must be exactly: flirty, witty, sweet.
- Each reply must be under 40 words.
- Write as the user, ready to send.
- Match the language of the transcript.
- Keep it confident, natural, and non-cringe.
- No explanations, no markdown, no extra keys.
"""


@router.post("/generate", response_model=APIResponse[GenerateData])
async def generate(body: GenerateRequest):
    transcript = body.transcript.strip()
    if not transcript:
        raise HTTPException(status_code=400, detail={"code": "empty_transcript", "message": "Transcript is required."})

    requested_styles = [style.strip().lower() for style in body.styles]
    if requested_styles != EXPECTED_STYLES:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "unsupported_reply_styles",
                "message": "Reply styles must be exactly flirty, witty, and sweet in order.",
            },
        )

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": transcript},
    ]

    try:
        content = await generate_chat_completion(get_settings(), messages)
        replies = parse_replies(content)
    except LLMClientError as exc:
        raise HTTPException(status_code=502, detail={"code": "reply_provider_error", "message": str(exc)}) from exc
    except ValueError as exc:
        raise HTTPException(status_code=502, detail={"code": "invalid_reply_payload", "message": str(exc)}) from exc

    return APIResponse(success=True, data=GenerateData(replies=replies))


def parse_replies(content: str) -> list[ReplySuggestion]:
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError as exc:
        raise ValueError("Reply provider did not return valid JSON.") from exc

    raw_replies = parsed.get("replies")
    if not isinstance(raw_replies, list) or len(raw_replies) != 3:
        raise ValueError("Reply provider must return exactly three replies.")

    replies: list[ReplySuggestion] = []
    for expected_style, raw_reply in zip(EXPECTED_STYLES, raw_replies, strict=True):
        if not isinstance(raw_reply, dict):
            raise ValueError("Reply item must be an object.")
        style = str(raw_reply.get("style", "")).strip().lower()
        text = str(raw_reply.get("text", "")).strip()
        if style != expected_style:
            raise ValueError("Reply styles must be flirty, witty, and sweet in order.")
        if not text:
            raise ValueError("Reply text cannot be empty.")
        replies.append(ReplySuggestion(style=style, text=text))
    return replies
