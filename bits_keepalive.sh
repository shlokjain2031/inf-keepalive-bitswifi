#!/usr/bin/env bash
set -euo pipefail

# BITS Wi-Fi keepalive URL
KEEPALIVE_URL="https://fw.bits-pilani.ac.in:8090/keepalive?0d05070d0d020f02"

# Hit every 5 seconds (very low CPU; process sleeps between requests)
INTERVAL_SECONDS=5

# Optional: if cert validation fails on campus firewall cert, set to true
INSECURE_TLS=false

echo "Starting keepalive loop (interval: ${INTERVAL_SECONDS}s)..."

while true; do
  if [ "$INSECURE_TLS" = true ]; then
    curl -kfsS --max-time 10 "$KEEPALIVE_URL" >/dev/null || true
  else
    curl -fsS --max-time 10 "$KEEPALIVE_URL" >/dev/null || true
  fi
  sleep "$INTERVAL_SECONDS"
done
