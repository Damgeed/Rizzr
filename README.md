# Rizzr

AI voice-note reply coach. Got a voice note? Rizzr it.

## Architecture

```
rizzr/
├── frontend/          # Static site (GitHub Pages)
│   ├── index.html     # Main app
│   ├── settings.html  # Theme switcher + preferences
│   ├── privacy.html   # Privacy policy
│   ├── pricing.html   # Pricing page
│   ├── assets/
│   │   ├── css/       # base.css + 3 theme files
│   │   ├── js/        # app.js, theme.js, recorder.js, api.js, i18n.js
│   │   └── img/       # Static assets
│   └── pages/        # Additional pages
├── backend/           # FastAPI (Railway)
│   ├── main.py        # App entry + middleware
│   ├── routers/       # transcribe, generate, tts
│   ├── middleware/    # rate_limit, security
│   ├── utils/         # helpers
│   └── Dockerfile
├── shared/            # Shared constants
└── .github/workflows/ # CI/CD
```

## Themes

| Theme | Default | Background | Accent |
|-------|---------|------------|--------|
| Sunset | ✅ | Coral→Orange→Gold | White text |
| Purple Dream | | Lavender | Purple→Pink gradient |
| Neon Nights | | Dark + Grid | Cyan + Hot Pink |

## Tech Stack

- **Frontend:** Vanilla HTML/CSS/JS, PWA, Web Audio API
- **Backend:** FastAPI, Python 3.11+
- **AI:** OpenAI Whisper, GLM-5.2 (kaiweb), ElevenLabs
- **Payments:** App Store / Google Play in-app purchases
- **Deploy:** GitHub Pages (frontend) + Railway (backend) + Cloudflare (DNS/Tunnel)
- **Security:** CORS lock, rate limiting, API key isolation, zero data persistence

## Dev

```bash
# Frontend
cd frontend && python3 -m http.server 8080

# Backend
cd backend && pip install -r requirements.txt && uvicorn main:app --reload
```
