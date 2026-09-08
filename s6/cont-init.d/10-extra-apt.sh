#!/command/with-contenv bash
# Install optional Debian packages requested through EXTRA_APT_PACKAGES.

set -Eeuo pipefail

log_dir="/data/logs"

log() {
  printf '[extra-apt] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${log_dir}/startup.log"
}

if [[ -z "${EXTRA_APT_PACKAGES:-}" ]]; then
  exit 0
fi

read -r -a extra_packages <<< "${EXTRA_APT_PACKAGES//,/ }"

# A value made only of spaces or commas resolves to zero package names; treat
# it the same as an unset value instead of calling apt-get install without
# package arguments.
(( ${#extra_packages[@]} > 0 )) || exit 0

for package in "${extra_packages[@]}"; do
  if [[ "$package" == -* ]]; then
    log "ERROR: invalid package name in EXTRA_APT_PACKAGES: ${package}"
    exit 1
  fi
done

log "Installing user-requested packages: ${extra_packages[*]}"
log "Updating APT package metadata..."
apt-get update
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${extra_packages[@]}"; then
  log "ERROR: unable to install EXTRA_APT_PACKAGES. Check the container logs."
  exit 1
fi
