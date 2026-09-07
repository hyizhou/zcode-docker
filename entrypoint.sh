#!/usr/bin/env bash
# Install the official ZCode package in the container when needed, then launch it in a virtual desktop.
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
startup_log="${log_dir}/startup.log"
app_root="/opt/ZCode"
app_bin="${app_root}/zcode"
app_marker="${app_root}/.zcode-install-complete"
installer="/tmp/zcode-linux-x64.deb"
release_page="/tmp/zcode-release.html"

mkdir -p "${ZCODE_DESKTOP_HOME_DIR}" \
         "${ZCODE_DESKTOP_USER_DATA_DIR}" \
         "${ZCODE_DESKTOP_SESSION_DATA_DIR}" \
         "${log_dir}" \
         /workspace
chown -R "${uid}:${gid}" /data
chown "${uid}:${gid}" /workspace 2>/dev/null || true

log() {
  printf '[zcode-entrypoint] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$startup_log"
}

clear_app_dir() {
  find "$app_root" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

apt_metadata_updated=false
update_apt_metadata() {
  if [[ "$apt_metadata_updated" == false ]]; then
    log "Updating APT package metadata..."
    apt-get update
    apt_metadata_updated=true
  fi
}

extra_packages=()
if [[ -n "${EXTRA_APT_PACKAGES:-}" ]]; then
  read -r -a extra_packages <<< "${EXTRA_APT_PACKAGES//,/ }"
fi

if (( ${#extra_packages[@]} > 0 )); then
  for package in "${extra_packages[@]}"; do
    if [[ "$package" == -* ]]; then
      log "ERROR: invalid package name in EXTRA_APT_PACKAGES: ${package}"
      exit 1
    fi
  done

  log "Installing user-requested packages: ${extra_packages[*]}"
  if ! update_apt_metadata || \
     ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${extra_packages[@]}"; then
    log "ERROR: unable to install EXTRA_APT_PACKAGES. Check the apt output above."
    exit 1
  fi
fi

need_install=false
if [[ -x "$app_bin" && -f "$app_marker" ]]; then
  log "Found an existing ZCode installation; skipping download."
else
  need_install=true
  log "No complete ZCode installation was found."
fi

if [[ "$need_install" == true ]]; then
  log "Fetching the latest ZCode release page..."
  if ! curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 \
    https://zcode.z.ai/cn -o "$release_page"; then
    log "ERROR: unable to fetch https://zcode.z.ai/cn. Check container network access."
    exit 1
  fi

  url="$(grep -oE 'https://cdn-zcode\.z\.ai/zcode/electron/releases/[0-9]+(\.[0-9]+)+/linux-x64/ZCode-[0-9]+(\.[0-9]+)+-linux-x64\.deb' "$release_page" | sort -uV | tail -n 1)"
  if [[ -z "$url" ]]; then
    log "ERROR: no Linux x64 ZCode .deb URL was found on the release page."
    rm -f "$release_page"
    exit 1
  fi
  log "Resolved installer URL: ${url}"

  log "Downloading ZCode. This can take several minutes; container logs will show progress."
  if ! curl -fL --retry 5 --retry-all-errors --connect-timeout 15 --progress-bar \
    "$url" -o "$installer"; then
    log "ERROR: unable to download ${url}. The container will stop; fix networking and start it again."
    rm -f "$installer" "$release_page"
    exit 1
  fi

  package_version="$(dpkg-deb -f "$installer" Version)"
  log "Download complete: version ${package_version}, $(du -h "$installer" | awk '{print $1}')."
  sha256sum "$installer" | tee -a "$startup_log"

  # Clear an incomplete installation only after the replacement installer has
  # downloaded successfully.
  mkdir -p "$app_root"
  clear_app_dir

  log "Installing ZCode in the container..."
  if ! update_apt_metadata || \
     ! DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall --no-install-recommends "$installer"; then
    log "ERROR: ZCode installation failed. The downloaded installer has been removed; check the apt output above."
    rm -f "$installer" "$release_page"
    exit 1
  fi

  if [[ ! -x "$app_bin" ]]; then
    log "ERROR: installer finished but ${app_bin} is missing or not executable."
    rm -f "$installer" "$release_page"
    exit 1
  fi

  chmod 4755 "${app_root}/chrome-sandbox"
  printf 'installed_at=%s\nversion=%s\nsource_url=%s\n' \
    "$(date -Is)" "$package_version" "$url" > "$app_marker"
  rm -f "$installer" "$release_page"
  log "ZCode ${package_version} installed successfully; the installer was removed."
fi

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
  log "ERROR: Xvfb failed to start."
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

log "Starting ZCode Desktop..."

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
