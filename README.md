I just found that to remain logged in at all times you just need to keep hitting the keepalive window. It resets the time you have remaining. 

Special credits to chrome developer tools and eyesight lol

# How to use
download `bits_keepalive.sh' and run it in the background so you just start it once and stop thinking about it.

## Manual run (any OS)

```bash
chmod +x bits_keepalive.sh
nohup ./bits_keepalive.sh > bits_keepalive.log 2>&1 &
```

The script now detects whether it is running on macOS or Linux and routes `--install`/`--status`/`--uninstall` to the appropriate platform-specific autostart helper.

## macOS (launchd)

The existing LaunchAgent flow is still the default on macOS.

```bash
./bits_keepalive.sh --install     # installs & loads ~/Library/LaunchAgents/com.bits.keepalive.plist
./bits_keepalive.sh --status      # shows the launchd state
./bits_keepalive.sh --uninstall   # unloads and removes the plist
```

## Linux (systemd user service)

Modern Linux distributions standardize on `systemd`, and the script now writes `~/.config/systemd/user/bits_keepalive.service` when you run it with `--install`.

```bash
chmod +x bits_keepalive.sh
./bits_keepalive.sh --install     # writes the unit and runs `systemctl --user enable --now`
./bits_keepalive.sh --status      # forwards to your systemd user manager
./bits_keepalive.sh --uninstall   # stops the service and removes the unit file
```

If you want the service to survive logout, enable user lingering with `sudo loginctl enable-linger "$USER"`. Use `systemctl --user status bits_keepalive.service` for more detail.

## Windows (Git Bash / WSL)
sorry u guys don't have bash by default

Run the script inside Git Bash or WSL and use the shell’s background operator so it keeps running even after you close the terminal:

```bash
chmod +x bits_keepalive.sh
./bits_keepalive.sh > bits_keepalive.log 2>&1 &
```

