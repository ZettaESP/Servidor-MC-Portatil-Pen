#!/usr/bin/env bash
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
PROPS="$BASE/server/server.properties"
PORT=$(awk -F= '$1=="server-port" {print $2}' "$PROPS" 2>/dev/null | tail -1); PORT=${PORT:-25565}
echo "=== RED DEL SERVIDOR ==="
echo "IP local:  $(hostname -I 2>/dev/null | awk '{print $1}')"
echo "Gateway:   $(ip route | awk '/default/ {print $3; exit}')"
echo "Puerto:    $PORT"
echo "IP pública (si está disponible):"
curl -4 -s --max-time 5 https://api.ipify.org || echo "No disponible"
echo
