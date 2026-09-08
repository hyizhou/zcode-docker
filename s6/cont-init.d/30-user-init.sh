#!/command/with-contenv bash
# Run the optional user-provided initialization scripts from the persistent
# volume: /data/init/root.sh as root, /data/init/user.sh as the zcode user.

set -Eeuo pipefail

log_dir="/data/logs"

log() {
  printf '[user-init] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${log_dir}/startup.log"
}

if [[ -f /data/init/root.sh ]]; then
  log "Running /data/init/root.sh as root..."
  if ! bash /data/init/root.sh; then
    log "ERROR: /data/init/root.sh exited with a non-zero status."
    exit 1
  fi
  log "/data/init/root.sh finished."
else
  log "No /data/init/root.sh found; skipping root customization."
fi

if [[ -f /data/init/user.sh ]]; then
  log "Running /data/init/user.sh as user zcode..."
  if ! /command/s6-setuidgid zcode env \
      HOME="${ZCODE_DESKTOP_HOME_DIR}" \
      USER=zcode \
      LOGNAME=zcode \
      XDG_RUNTIME_DIR=/run/user/1000 \
      bash /data/init/user.sh; then
    log "ERROR: /data/init/user.sh exited with a non-zero status."
    exit 1
  fi
  log "/data/init/user.sh finished."
else
  log "No /data/init/user.sh found; skipping user customization."
fi
