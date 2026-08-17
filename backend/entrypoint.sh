#!/bin/bash
set -euo pipefail

if [ -n "${CLOUDFLARED_TUNNEL_TOKEN:-}" ]; then
  echo "Starting Cloudflare Tunnel..." >&2
  cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARED_TUNNEL_TOKEN" &
fi

PORT_VALUE="${PORT:-8000}"
echo "Starting Rizzr API on port ${PORT_VALUE}..." >&2

exec python main.py
