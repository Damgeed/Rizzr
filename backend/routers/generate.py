"""Rizzr — LLM Reply Generation Router

POST /api/generate
- Receives transcript text
- Calls LLM (GLM-5.2 via kaiweb gateway) to generate 3 reply styles
- Returns results via SSE streaming (not waiting for all 3)
- Each reply is forwarded as it completes
"""
import json
import httpx
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from config import get_settings

router = APIRouter()

SYSTEM_PROMPT = """You are a social reply coach. The user received a voice message and needs reply suggestions.
Generate exactly 3 reply styles:

A (Flirty): Confident, playful, slightly teasing but not over the top.
B (Witty): Humorous, clever, good-natured jokes.
C (Chill): Natural, relaxed, genuine.

Rules:
- Each reply must be under 50 words.
- Write as if the user is saying it (first person).
- Match the language of the original message (if they spoke Chinese, reply in Chinese).
- No explanations, no analysis — just the 3 replies.
- Format each as: A: <reply> B: <reply> C: <reply>
"""


class GenerateRequest(BaseModel):
    transcript: str
    session_id: str = ""


@router.post("/api/generate")
async def generate(request: Request, body: GenerateRequest):
    settings = get_settings()

    if not body.transcript.strip():
        raise HTTPException(status_code=400, detail="Empty transcript")

    # Build messages
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": body.transcript},
    ]

    llm_url = f"{settings.llm_base_url}/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.llm_api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": settings.llm_model,
        "messages": messages,
        "temperature": 0.8,
        "max_tokens": 500,
        "stream": True,
    }

    async def stream_replies():
        full_text = ""
        style_map = {"A": "flirty", "B": "witty", "C": "chill"}

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                async with client.stream("POST", llm_url, headers=headers, json=payload) as resp:
                    resp.raise_for_status()
                    async for line in resp.aiter_lines():
                        if not line.startswith("data: "):
                            continue
                        data = line[6:].strip()
                        if data == "[DONE]":
                            break
                        try:
                            chunk = json.loads(data)
                            delta = chunk.get("choices", [{}])[0].get("delta", {})
                            content = delta.get("content", "")
                            if content:
                                full_text += content
                                # Stream partial text to client
                                yield f"data: {json.dumps({'type': 'partial', 'text': content})}\n\n"
                        except (json.JSONDecodeError, IndexError):
                            continue

            # Parse complete text into 3 replies
            replies = parse_replies(full_text)
            for i, (style_label, reply_text) in enumerate(replies):
                style = style_map.get(style_label, "chill")
                yield f"data: {json.dumps({'type': 'reply_complete', 'index': i, 'style': style, 'text': reply_text})}\n\n"

            yield f"data: {json.dumps({'type': 'done'})}\n\n"

        except httpx.TimeoutException:
            yield f"data: {json.dumps({'type': 'error', 'message': 'LLM timed out'})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(
        stream_replies(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


def parse_replies(text: str) -> list[tuple[str, str]]:
    """Parse 'A: ... B: ... C: ...' into list of (label, text)."""
    import re
    # Match A:, B:, C: prefixes
    pattern = r'([ABC]):\s*(.+?)(?=[ABC]:|$)'
    matches = re.findall(pattern, text, re.DOTALL)
    return [(label.strip(), reply.strip()) for label, reply in matches]
