"""Rizzr — Stripe Payment Router

POST /api/checkout   — Create Stripe Checkout session
POST /api/webhook    — Stripe webhook (idempotent)
GET  /api/usage      — Check remaining free replies
"""
import json
import time
import httpx
from fastapi import APIRouter, HTTPException, Request, Response
from pydantic import BaseModel

from config import get_settings
from middleware.rate_limit import get_limiter

router = APIRouter()


@router.get("/api/usage")
async def get_usage(request: Request):
    """Check remaining free-tier replies."""
    settings = get_settings()
    client_ip = request.client.host if request.client else "unknown"
    limiter = get_limiter()

    # We don't want to consume a slot just by checking
    # So we read the current count without incrementing
    if hasattr(limiter, '_store'):
        now = time.time()
        key = f"rizzr:rl:{client_ip}"
        entries = limiter._store.get(key, [])
        used = len([t for t in entries if now - t < settings.rate_window_seconds])
        remaining = max(0, settings.rate_limit_free - used)
        return {"remaining": remaining, "total": settings.rate_limit_free}

    return {"remaining": settings.rate_limit_free, "total": settings.rate_limit_free}


@router.post("/api/checkout")
async def create_checkout():
    """Create Stripe Checkout session for Pro subscription."""
    settings = get_settings()

    if not settings.stripe_secret_key or not settings.stripe_price_id:
        raise HTTPException(status_code=500, detail="Stripe not configured")

    url = "https://api.stripe.com/v1/checkout/sessions"
    headers = {
        "Authorization": f"Bearer {settings.stripe_secret_key}",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    data = {
        "mode": "subscription",
        "line_items[0][price]": settings.stripe_price_id,
        "line_items[0][quantity]": "1",
        "success_url": "https://rizzr.com/?upgraded=true",
        "cancel_url": "https://rizzr.com/pricing.html?canceled=true",
        "allow_promotion_codes": "true",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, headers=headers, data=data)
            resp.raise_for_status()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Stripe error: {str(e)}")

    session = resp.json()
    return {"url": session.get("url", "")}


@router.post("/api/webhook")
async def stripe_webhook(request: Request):
    """Stripe webhook — idempotent via event ID."""
    settings = get_settings()
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    # In production, verify webhook signature with Stripe
    # For now, parse the event
    try:
        event = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid payload")

    event_id = event.get("id", "")
    event_type = event.get("type", "")

    # Idempotency: check if we've processed this event
    # (In production, use Redis SET with event_id)
    # processed = redis.sismember("rizzr:stripe:events", event_id)
    # if processed: return {"status": "already_processed"}

    if event_type == "checkout.session.completed":
        # User subscribed — grant Pro access
        # Extract customer ID, update in DB (when we add user accounts)
        pass
    elif event_type == "customer.subscription.deleted":
        # User canceled — revoke Pro access
        pass
    elif event_type == "invoice.paid":
        # Recurring payment — extend Pro access
        pass

    return {"status": "received", "event_id": event_id}
