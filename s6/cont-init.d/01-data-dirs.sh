#!/command/with-contenv bash
# Prepare writable directories, ownership, and the VNC password file.

set -Eeuo pipefail

uid=1000
gid=1000
vnc_password="${VNC_PASSWORD:-zcode123}"
vnc_pass="/data/.vnc/pass"

mkdir -p \
  "${ZCODE_DESKTOP_HOME_DIR}" \
  "${ZCODE_DESKTOP_USER_DATA_DIR}" \
  "${ZCODE_DESKTOP_SESSION_DATA_DIR}" \
  /data/logs \
  /data/init \
  /data/.vnc \
  /workspace \
  /run/user/1000 \
  /tmp/.X11-unix

chown -R "${uid}:${gid}" \
  "${ZCODE_DESKTOP_HOME_DIR}" \
  "${ZCODE_DESKTOP_USER_DATA_DIR}" \
  "${ZCODE_DESKTOP_SESSION_DATA_DIR}" \
  /data/logs \
  /data/.vnc
# /workspace is intentionally not chowned here: it is bind-mounted from the
# host in the Compose setup, and changing its ownership would modify the host
# directory instead of the container.
chown "${uid}:${gid}" /data 2>/dev/null || true
chown "${uid}:${gid}" /run/user/1000 /tmp/.X11-unix 2>/dev/null || true
chmod 700 /run/user/1000

x11vnc -storepasswd "${vnc_password}" "${vnc_pass}" >/dev/null 2>&1
chown "${uid}:${gid}" "${vnc_pass}"
chmod 600 "${vnc_pass}"
