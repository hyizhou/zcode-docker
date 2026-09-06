[English](README.md) | [简体中文](README.zh-CN.md)

# ZCode Headless Server

An unofficial Docker setup for running ZCode Desktop continuously on a server without a physical display. It is intended for long-running development tasks, so your own computer does not need to stay on.

## Features

- Automatically downloads the latest official Linux x64 ZCode `.deb` package
- Runs a virtual display with Xvfb
- Runs the Openbox window manager
- Supports ZCode's official remote-control feature
- Provides x11vnc and noVNC as a backup web VNC interface
- Persists login state, configuration, session data, and task state
- Mounts a local workspace

## Requirements

- Linux x64 / amd64
- Docker Engine
- Docker Compose v2

## Usage

Install Docker Engine and Docker Compose v2 first.

```bash
git clone https://github.com/hyizhou/zcode-docker.git
cd zcode-docker
docker compose up -d --build
```

1. Open this address in a browser:

```text
http://<server-ip>:6080/
```

2. Enter the desktop using the password specified by `VNC_PASSWORD`.

3. Sign in to your ZCode account.
4. Connect this device using ZCode's official remote-control feature.
5. Add your projects to ZCode.
6. Develop through ZCode's official remote control.
7. Close the browser. After remote-control pairing is complete, block port `6080` with a host firewall, Docker firewall chain, or cloud security group. Allow it temporarily only when the backup VNC interface is needed.

Before first use, change `VNC_PASSWORD` in `docker-compose.yml`:

```yaml
VNC_PASSWORD: "change-me"
```

## Persistent data

Data is stored in:

- `/data`: login state, configuration, sessions, and logs
- `/workspace`: the workspace directory used by ZCode

Login state is preserved by:

```bash
docker compose restart
docker compose down
docker compose up -d
```

Only `down -v` or manually deleting the named volume removes `/data`.

## Nightly free period

For paid GLM Coding Plan subscribers using GLM-5.3-Flash in ZCode, quota consumption is zero from September 3 through September 20, 2026, every day from 23:00 to 09:00 Beijing time. Weekends and public holidays are included. See the [official event page](https://docs.bigmodel.cn/cn/coding-plan/notice/event-glm-5.3-flash) for details.

## Updating ZCode

The build parses the latest official Linux x64 package URL. Because Docker caches build layers, force a fresh version check with:

```bash
docker compose build --no-cache
docker compose up -d
```

## Build variable

`APT_MIRROR_HOST`: Debian APT mirror hostname. Set it when you want to use another mirror.

```bash
APT_MIRROR_HOST=mirrors.aliyun.com docker compose build --no-cache
```

## Common commands

```bash
docker compose logs -f
docker compose ps
docker stats zcode-webvnc
docker compose exec zcode bash
docker compose restart
docker compose down
```

## Security notes

- Change the default VNC password.
- `/data` contains login credentials and session data. Do not share it casually.
- Avoid exposing port `6080` directly to the public internet. For public access, use a reverse proxy, VPN, or firewall, and enable HTTPS.

## Disclaimer

This is an unofficial deployment configuration. ZCode and its installer are copyrighted by their official owners. Use this project in accordance with ZCode's terms of service.
