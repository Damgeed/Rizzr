# Rizzr — Product Requirements Document

## Overview
Rizzr is an AI voice-note reply coach. Users receive voice messages on WhatsApp/IG/iMessage, and Rizzr generates 3 perfect reply suggestions (Flirty, Witty, Chill) with TTS voice previews.

## Problem
Gen Z users receive voice notes but struggle to think of good replies. Existing AI tools are text-only — none handle voice-to-voice reply coaching.

## Solution
A mobile-first PWA: record/upload a voice note → Whisper transcribes → LLM generates 3 styled replies → ElevenLabs renders TTS previews → user copies text or downloads audio.

## MVP Features (Phase 1)
| # | Feature | Status |
|---|---------|--------|
| 1 | Voice recording (MediaRecorder API) | ✅ scaffolded |
| 2 | File upload (audio) | ✅ scaffolded |
| 3 | Whisper transcription | ✅ backend ready |
| 4 | LLM reply generation (SSE streaming) | ✅ backend ready |
| 5 | TTS voice preview (ElevenLabs) | ✅ backend ready |
| 6 | 3 reply styles (Flirty/Witty/Chill) | ✅ in prompt |
| 7 | Copy text + download voice | ✅ frontend ready |
| 8 | Freemium paywall (3/day, $9.99/mo) | ✅ Stripe scaffolded |
| 9 | 3 themes (Sunset/Purple Dream/Neon Nights) | ✅ implemented |
| 10 | Random taglines on refresh | ✅ implemented |
| 11 | Multi-page (Home/Settings/Pricing/Privacy) | ✅ implemented |

## v2 Features (Phase 2 — post-validation)
- Ghost mode (gradual fade-out reply sequences)
- Social exit assistant
- Voice cloning
- Emotion detection
- History + favorites

## Architecture
- **Frontend:** Vanilla HTML/CSS/JS PWA → GitHub Pages
- **Backend:** FastAPI → Railway → Cloudflare Tunnel
- **AI:** OpenAI Whisper + GLM-5.2 (kaiweb) + ElevenLabs
- **Payments:** Stripe Checkout + Webhooks

## Security
- API keys server-side only (zero frontend exposure)
- CORS locked to production domains
- Rate limiting (IP-based, sliding window)
- Request size limit (30MB)
- Security headers (X-Frame-Options, CSP, etc.)
- Zero data persistence (audio deleted after transcription)
- Trusted host middleware (prod only)

## Pricing
- Free: 3 replies/day
- Pro: $9.99/month, unlimited

## Cost per use (free tier)
- Whisper: ~$0.006/min
- LLM: free (kaiweb)
- TTS: ~$0.18/1000 chars
- Total per use: ~$0.01
- 3 free/day = ~$0.03/day/free user
