FROM buildpack-deps:bookworm-curl

ARG APT_MIRROR_HOST=deb.debian.org

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:99 \
    NO_AT_BRIDGE=1 \
    ZCODE_DESKTOP_HOME_DIR=/data/home \
    ZCODE_DESKTOP_USER_DATA_DIR=/data/user-data \
    ZCODE_DESKTOP_SESSION_DATA_DIR=/data/session

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian|https://${APT_MIRROR_HOST}/debian|g" \
      -e "s|http://deb.debian.org/debian-security|https://${APT_MIRROR_HOST}/debian-security|g" \
      /etc/apt/sources.list.d/debian.sources; \
    apt-get update; \
    curl -fsSL https://zcode.z.ai/cn -o /tmp/zcode-release.html; \
    url="$(grep -oE 'https://cdn-zcode\.z\.ai/zcode/electron/releases/[0-9]+(\.[0-9]+)+/linux-x64/ZCode-[0-9]+(\.[0-9]+)+-linux-x64\.deb' /tmp/zcode-release.html | sort -uV | tail -n 1)"; \
    test -n "$url"; \
    curl -fL "$url" -o /tmp/zcode.deb; \
    apt-get install -y --no-install-recommends \
      tzdata procps xvfb dbus dbus-x11 gnome-keyring gosu \
      x11vnc novnc websockify openbox surf \
      fonts-wqy-zenhei fonts-noto-color-emoji \
      libasound2 libgbm1 \
      /tmp/zcode.deb; \
    chmod 4755 /opt/ZCode/chrome-sandbox; \
    groupadd --gid 1000 zcode; \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash zcode; \
    install -d -o zcode -g zcode /data /workspace; \
    rm -f /tmp/zcode.deb /tmp/zcode-release.html; \
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html; \
    ln -sf /usr/bin/surf /usr/local/bin/x-www-browser; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint.sh /usr/local/bin/zcode-entrypoint

WORKDIR /workspace
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD pgrep -x zcode >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/zcode-entrypoint"]
CMD ["/opt/ZCode/zcode"]
