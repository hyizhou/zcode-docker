#!/usr/bin/env bash
set -Eeuo pipefail

uid=1000
gid=1000
display=":99"
width=1440
height=900
depth="24"
vnc_port="5900"
novnc_port=6080
vnc_password="${VNC_PASSWORD:-zcode123}"
log_dir="/data/logs"

mkdir -p "${ZCODE_DESKTOP_HOME_DIR}" \
         "${ZCODE_DESKTOP_USER_DATA_DIR}" \
         "${ZCODE_DESKTOP_SESSION_DATA_DIR}" \
         "${log_dir}" \
         /workspace
chown -R "${uid}:${gid}" /data
chown "${uid}:${gid}" /workspace 2>/dev/null || true

display_number="${display#:}"
display_number="${display_number%%.*}"
x_lock="/tmp/.X${display_number}-lock"
x_socket="/tmp/.X11-unix/X${display_number}"
rm -f "$x_lock" "$x_socket"

gosu "${uid}:${gid}" Xvfb "$display" \
  -noreset \
  -nolisten tcp \
  -screen 0 "${width}x${height}x${depth}" \
  -dpi 96 \
  +extension GLX \
  +render \
  -ac >"${log_dir}/xvfb.log" 2>&1 &
xvfb_pid=$!

for _ in $(seq 1 50); do
  [[ -S "$x_socket" ]] && break
  kill -0 "$xvfb_pid" >/dev/null 2>&1 || break
  sleep 0.1
done

if [[ ! -S "$x_socket" ]] || ! kill -0 "$xvfb_pid" >/dev/null 2>&1; then
  cat "${log_dir}/xvfb.log" >&2
  exit 1
fi

gosu "${uid}:${gid}" bash -c \
  'dbus-launch --sh-syntax' >"${log_dir}/dbus.env" 2>&1
# shellcheck disable=SC1090
source "${log_dir}/dbus.env"
export DBUS_SESSION_BUS_ADDRESS

gosu "${uid}:${gid}" openbox-session >"${log_dir}/openbox.log" 2>&1 &

vnc_pass="/data/.vnc/pass"
mkdir -p "$(dirname "$vnc_pass")"
x11vnc -storepasswd "$vnc_password" "$vnc_pass" >/dev/null 2>&1
chown -R "${uid}:${gid}" "$(dirname "$vnc_pass")"
gosu "${uid}:${gid}" x11vnc \
  -display "$display" \
  -rfbport "$vnc_port" \
  -rfbauth "$vnc_pass" \
  -shared -forever -noxdamage \
  -o "${log_dir}/x11vnc.log" -bg >/dev/null 2>&1

gosu "${uid}:${gid}" websockify \
  --web /usr/share/novnc \
  "0.0.0.0:${novnc_port}" \
  "127.0.0.1:${vnc_port}" \
  >"${log_dir}/novnc.log" 2>&1 &

if [[ "$1" != "/opt/ZCode/zcode" ]]; then
  exec "$@"
fi

args=(
  --disable-gpu
  --disable-dev-shm-usage
  --disable-background-timer-throttling
  --disable-backgrounding-occluded-windows
  --disable-renderer-backgrounding
  --no-first-run
  --window-size="${width},${height}"
)
args+=(--no-sandbox --password-store=basic)

exec gosu "${uid}:${gid}" env \
  HOME="${ZCODE_DESKTOP_HOME_DIR}" \
  DISPLAY="$display" \
  DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}" \
  /opt/ZCode/zcode "${args[@]}"
