# ZCode headless desktop image: s6-overlay supervises the virtual display,
# D-Bus, window manager, VNC stack, and the official ZCode Desktop binary.
FROM buildpack-deps:bookworm-curl

ARG APT_MIRROR_HOST=deb.debian.org
ARG S6_OVERLAY_VERSION=3.2.2.0

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:99 \
    NO_AT_BRIDGE=1 \
    ZCODE_DESKTOP_HOME_DIR=/data/home \
    ZCODE_DESKTOP_USER_DATA_DIR=/data/user-data \
    ZCODE_DESKTOP_SESSION_DATA_DIR=/data/session \
    VNC_ENABLED=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian|https://${APT_MIRROR_HOST}/debian|g" \
      -e "s|http://deb.debian.org/debian-security|https://${APT_MIRROR_HOST}/debian-security|g" \
      /etc/apt/sources.list.d/debian.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      tzdata procps xz-utils xvfb dbus gnome-keyring \
      x11vnc novnc websockify openbox surf \
      git \
      fonts-wqy-zenhei fonts-noto-color-emoji \
      libasound2 libgbm1 \
      libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
      xdg-utils libatspi2.0-0 libuuid1 libsecret-1-0; \
    groupadd --gid 1000 zcode; \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash zcode; \
    install -d -o zcode -g zcode /data /workspace; \
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html; \
    ln -sf /usr/bin/surf /usr/local/bin/x-www-browser; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Install the pinned s6-overlay release and verify both tarballs against the
# checksum files published with that release before extracting them.
RUN set -eux; \
    s6_base="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"; \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 \
      -o /tmp/s6-overlay-noarch.tar.xz "${s6_base}/s6-overlay-noarch.tar.xz"; \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 \
      -o /tmp/s6-overlay-noarch.tar.xz.sha256 "${s6_base}/s6-overlay-noarch.tar.xz.sha256"; \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 \
      -o /tmp/s6-overlay-x86_64.tar.xz "${s6_base}/s6-overlay-x86_64.tar.xz"; \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 \
      -o /tmp/s6-overlay-x86_64.tar.xz.sha256 "${s6_base}/s6-overlay-x86_64.tar.xz.sha256"; \
    cd /tmp; \
    sha256sum -c s6-overlay-noarch.tar.xz.sha256; \
    sha256sum -c s6-overlay-x86_64.tar.xz.sha256; \
    tar -C / -Jxpf s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf s6-overlay-x86_64.tar.xz; \
    rm -f s6-overlay-noarch.tar.xz s6-overlay-noarch.tar.xz.sha256 \
          s6-overlay-x86_64.tar.xz s6-overlay-x86_64.tar.xz.sha256

COPY s6/cont-init.d/ /etc/cont-init.d/
COPY s6/s6-rc.d/ /etc/s6-overlay/s6-rc.d/
COPY s6/wait-socket.sh /etc/s6-overlay/wait-socket.sh
RUN chmod +x /etc/cont-init.d/*.sh \
  && find /etc/s6-overlay/s6-rc.d -type f -name run -exec chmod +x {} +

WORKDIR /workspace
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10m --retries=3 \
  CMD pgrep -x zcode >/dev/null || exit 1

ENTRYPOINT ["/init"]
