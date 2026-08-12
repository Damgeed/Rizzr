#!/bin/bash
set -e

# Start cloudflared tunnel in background (if configured)
if [ -n "$CLOUDFLARED_TUNNEL_TOKEN" ]; then
  echo "Starting Cloudflare Tunnel..."
  cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARED_TUNNEL_TOKEN" &
fi

# Start FastAPI
echo "Starting Rizzr API on port ${PORT:-8000}..."
exec uvicorn main:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --workers 2 \
  --proxy-headers \
  --forwarded-allow-ips '*'
