#!/command/with-contenv bash
# Download and install the official ZCode package when it is missing from the
# container layer.

set -Eeuo pipefail

log_dir="/data/logs"
app_root="/opt/ZCode"
app_bin="${app_root}/zcode"
app_marker="${app_root}/.zcode-install-complete"
installer="/tmp/zcode-linux-x64.deb"
release_page="/tmp/zcode-release.html"
apt_metadata_updated=false

log() {
  printf '[zcode-install] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${log_dir}/startup.log"
}

update_apt_metadata() {
  if [[ "$apt_metadata_updated" == false ]]; then
    log "Updating APT package metadata..."
    apt-get update
    apt_metadata_updated=true
  fi
}

if [[ -x "$app_bin" && -f "$app_marker" ]]; then
  log "Found an existing ZCode installation; skipping download."
  exit 0
fi

log "No complete ZCode installation was found."
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
sha256sum "$installer" | tee -a "${log_dir}/startup.log"

# Clear an incomplete installation only after the replacement installer has
# downloaded successfully.
mkdir -p "$app_root"
find "$app_root" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

log "Installing ZCode in the container..."
if ! update_apt_metadata || \
   ! DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall --no-install-recommends "$installer"; then
  log "ERROR: ZCode installation failed. The downloaded installer has been removed; check the container logs."
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
