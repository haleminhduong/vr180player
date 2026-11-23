#!/usr/bin/env bash
# Launch VR180 Player on a Steam Deck with XR glasses.
# - reads mouse_sensitivity from the XR driver config so head angles map 1:1
# - switches the glasses into 3D SBS mode, and back to 2D on exit
# - serves the page locally and opens it in a Chromium-based browser in kiosk mode
set -u
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${VR180_PORT:-8180}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/xr_driver/config.ini"
CONTROL=/dev/shm/xr_driver_control
STATE=/dev/shm/xr_driver_state

sens=30
if [ -f "$CONFIG" ]; then
  v=$(sed -n 's/^mouse_sensitivity=\([0-9]*\).*/\1/p' "$CONFIG" | tail -1)
  [ -n "$v" ] && sens="$v"
  if grep -q '^disabled=true' "$CONFIG"; then
    echo "warning: XR driver is disabled. Run: xr_driver_cli -e" >&2
  fi
  if grep -q '^output_mode=' "$CONFIG" && ! grep -q '^output_mode=mouse' "$CONFIG"; then
    echo "warning: XR driver is not in mouse mode. Run: xr_driver_cli --use-mouse" >&2
  fi
else
  echo "warning: $CONFIG not found, assuming mouse_sensitivity=30" >&2
fi

sbs_param=1
if [ "${VR180_NO_SBS:-0}" != 1 ] && grep -q '^sbs_mode_supported=true' "$STATE" 2>/dev/null; then
  echo "sbs_mode=enable" > "$CONTROL"
else
  sbs_param=0
  echo "note: glasses SBS mode not available, starting in 2D output" >&2
fi

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$APP_DIR" >/dev/null 2>&1 &
server=$!

cleanup() {
  kill "$server" 2>/dev/null
  [ "$sbs_param" = 1 ] && echo "sbs_mode=disable" > "$CONTROL"
}
trap cleanup EXIT INT TERM
sleep 0.5

url="http://127.0.0.1:$PORT/index.html?sens=$sens&sbs=$sbs_param${VR180_ARGS:+&$VR180_ARGS}"
for app in com.google.Chrome org.chromium.Chromium com.microsoft.Edge com.brave.Browser; do
  if flatpak info "$app" >/dev/null 2>&1; then
    flatpak run "$app" --kiosk --start-fullscreen --no-first-run \
      --user-data-dir="$HOME/.var/app/$app/vr180player-profile" "--app=$url"
    exit
  fi
done
if command -v chromium >/dev/null; then chromium --kiosk "--app=$url"; exit; fi
if flatpak info org.mozilla.firefox >/dev/null 2>&1; then flatpak run org.mozilla.firefox --kiosk "$url"; exit; fi
echo "No supported browser found. Install Google Chrome from Discover." >&2
exit 1
