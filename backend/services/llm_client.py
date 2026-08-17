"""OpenAI-compatible chat completion client for Rizzr."""
from __future__ import annotations

import json
from typing import Any

import httpx

from config import Settings


class LLMClientError(RuntimeError):
    pass


async def generate_chat_completion(settings: Settings, messages: list[dict[str, str]]) -> str:
    settings.require_llm_key()

    payload: dict[str, Any] = {
        "model": settings.llm_model,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 450,
        "stream": False,
        "response_format": {"type": "json_object"},
    }
    headers = {
        "Authorization": f"Bearer {settings.llm_api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(f"{settings.llm_base_url.rstrip('/')}/chat/completions", headers=headers, json=payload)
            response.raise_for_status()
    except httpx.TimeoutException as exc:
        raise LLMClientError("Reply generation timed out.") from exc
    except httpx.HTTPStatusError as exc:
        raise LLMClientError(f"LLM provider failed with status {exc.response.status_code}.") from exc
    except httpx.HTTPError as exc:
        raise LLMClientError("LLM provider request failed.") from exc

    try:
        data = response.json()
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
        raise LLMClientError("LLM provider returned an invalid response.") from exc

    if not isinstance(content, str) or not content.strip():
        raise LLMClientError("LLM provider returned an empty response.")
    return content.strip()
