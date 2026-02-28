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

OS_TYPE="$(uname -s)"
SYSTEMD_SERVICE_NAME="bits_keepalive.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SYSTEMD_SERVICE_PATH="$SYSTEMD_USER_DIR/$SYSTEMD_SERVICE_NAME"

is_macos() {
  [ "$OS_TYPE" = "Darwin" ]
}

is_linux() {
  [ "$OS_TYPE" = "Linux" ]
}

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

install_autostart_macos() {
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

install_autostart_linux() {
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl not available; install not supported on ${OS_TYPE}."
    return 1
  fi

  mkdir -p "$SYSTEMD_USER_DIR"

  cat >"$SYSTEMD_SERVICE_PATH" <<EOF
[Unit]
Description=BITS Wi-Fi keepalive loop
After=network-online.target

[Service]
ExecStart=${SCRIPT_PATH} --run
Restart=always
RestartSec=${INTERVAL_SECONDS}
StartLimitIntervalSec=60
StartLimitBurst=3

[Install]
WantedBy=default.target
EOF

  if ! systemctl --user daemon-reload >/dev/null 2>&1; then
    echo "Warning: could not reload systemd user units; ensure a user manager is running."
  fi

  if systemctl --user enable --now "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1; then
    echo "Installed and started background keepalive via systemd user service."
    echo "It will run for your login session and restart automatically."
  else
    echo "Service file written to $SYSTEMD_SERVICE_PATH but enabling it failed."
    echo "Run \"systemctl --user enable --now $SYSTEMD_SERVICE_NAME\" once the user manager is active."
  fi
}

install_autostart() {
  if is_macos; then
    install_autostart_macos
  elif is_linux; then
    install_autostart_linux
  else
    echo "Autostart is not supported on ${OS_TYPE}."
    exit 1
  fi
}

uninstall_autostart_macos() {
  launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
  rm -f "$PLIST_PATH"
  echo "Removed background keepalive autostart."
}

uninstall_autostart_linux() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1 || true
    systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
  rm -f "$SYSTEMD_SERVICE_PATH"
  echo "Removed background keepalive autostart."
}

uninstall_autostart() {
  if is_macos; then
    uninstall_autostart_macos
  elif is_linux; then
    uninstall_autostart_linux
  else
    echo "Autostart is not supported on ${OS_TYPE}."
    exit 1
  fi
}

status_autostart_macos() {
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

status_autostart_linux() {
  if [ ! -f "$SYSTEMD_SERVICE_PATH" ]; then
    echo "Status: not installed."
    return
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user is-active --quiet "$SYSTEMD_SERVICE_NAME"; then
      echo "Status: installed and running via systemd user service ($SYSTEMD_SERVICE_NAME)."
    elif systemctl --user is-enabled --quiet "$SYSTEMD_SERVICE_NAME"; then
      echo "Status: installed but not currently running (systemd user service)."
    else
      echo "Status: installed but disabled (systemd user service)."
    fi
  else
    echo "Status: service file present but systemctl is unavailable."
  fi

  echo "Service file: $SYSTEMD_SERVICE_PATH"
}

status_autostart() {
  if is_macos; then
    status_autostart_macos
  elif is_linux; then
    status_autostart_linux
  else
    echo "Autostart is not supported on ${OS_TYPE}."
    exit 1
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
