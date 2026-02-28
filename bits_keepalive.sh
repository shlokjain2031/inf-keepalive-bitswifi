#!/usr/bin/env bash
set -euo pipefail

# BITS Wi-Fi keepalive URL
KEEPALIVE_URL="https://fw.bits-pilani.ac.in:8090/keepalive?0d05070d0d020f02"

# Hit every 5 seconds (very low CPU; process sleeps between requests)
INTERVAL_SECONDS=5

# Optional: if cert validation fails on campus firewall cert, set to true
INSECURE_TLS=false

LABEL="com.bits.keepalive"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

run_loop() {
  echo "Starting keepalive loop (interval: ${INTERVAL_SECONDS}s)..."
  while true; do
    if [ "$INSECURE_TLS" = true ]; then
      curl -kfsS --max-time 10 "$KEEPALIVE_URL" >/dev/null || true
    else
      curl -fsS --max-time 10 "$KEEPALIVE_URL" >/dev/null || true
    fi
    sleep "$INTERVAL_SECONDS"
  done
}

install_autostart() {
  mkdir -p "$HOME/Library/LaunchAgents"

  cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT_PATH}</string>
    <string>--run</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/bits_keepalive.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/bits_keepalive.error.log</string>
</dict>
</plist>
EOF

  launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
  launchctl load "$PLIST_PATH"

  echo "Installed and started background keepalive."
  echo "It will auto-start after reboot/login."
}

uninstall_autostart() {
  launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
  rm -f "$PLIST_PATH"
  echo "Removed background keepalive autostart."
}

status_autostart() {
  if [ -f "$PLIST_PATH" ]; then
    if launchctl list | grep -q "$LABEL"; then
      echo "Status: installed and currently running via launchd (${LABEL})."
    else
      echo "Status: installed but not currently loaded (${LABEL})."
    fi
    echo "Plist: $PLIST_PATH"
  else
    echo "Status: not installed."
  fi
}

case "${1:-}" in
  --run)
    run_loop
    ;;
  --install)
    install_autostart
    ;;
  --uninstall)
    uninstall_autostart
    ;;
  --status)
    status_autostart
    ;;
  "")
    install_autostart
    ;;
  *)
    echo "Usage: $0 [--install|--run|--status|--uninstall]"
    exit 1
    ;;
esac
