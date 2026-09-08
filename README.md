[English](README.md) | [简体中文](README.zh-CN.md)

# ZCode Headless Server

An unofficial Docker setup for running ZCode Desktop continuously on a server without a physical display. It is intended for long-running development tasks, so your own computer does not need to stay on.

> For paid GLM Coding Plan subscribers using GLM-5.3-Flash in ZCode, quota consumption is zero from September 3 through September 20, 2026, every day from 23:00 to 09:00 Beijing time. Weekends and public holidays are included. See the [official event page](https://docs.bigmodel.cn/cn/coding-plan/notice/event-glm-5.3-flash) for details.

## Requirements

- Linux x64 / amd64
- Docker Engine
- Docker Compose v2

## Usage

```bash
git clone https://github.com/hyizhou/zcode-docker.git
cd zcode-docker
cp docker-compose.example.yml docker-compose.yml
mkdir -p workspace   # directory mounted into the container; usable as a ZCode workspace, and ZCode can use other paths
                     # create it before startup, otherwise Docker creates it root-owned; the mount path can be changed in compose
docker compose up -d --build
```

1. Open this address in a browser:

```text
http://<server-ip>:6080/
```

2. Enter the desktop using the password specified by `VNC_PASSWORD`; consider changing the default in `docker-compose.yml`.

3. Sign in to ZCode, complete remote-control pairing, and add your projects.
4. Close the browser. After pairing, block port `6080` with a host firewall, Docker firewall chain, or cloud security group, or set `VNC_ENABLED=0` and recreate the container to stop the VNC services. Re-open the port temporarily whenever you need the backup VNC interface.

## Environment variables

Set them in the `environment` block of `docker-compose.yml`, or in a `.env` file next to the Compose file (ignored by Git):

| Variable | Default | Description |
| --- | --- | --- |
| `VNC_PASSWORD` | `zcode123` | Password for the backup web VNC interface. Change it before first use. |
| `VNC_ENABLED` | `1` | Set to `0` to keep the backup VNC services stopped, so nothing listens on port `6080`; useful after official remote-control pairing. ZCode and its remote control keep working. |
| `EXTRA_APT_PACKAGES` | empty | Debian packages installed at every container start, separated by spaces or commas. They are installed as root, while ZCode keeps running as the unprivileged `zcode` user. |

Environment variables are fixed when the container is created. After changing them, run `docker compose up -d` to apply the new values.

## Persistent data

Data is stored in:

- `/data`: login state, configuration, sessions, and logs
- `/workspace`: a directory mounted into the container, usable as the ZCode workspace; ZCode can also use other paths

## Custom startup scripts

The image ships only the base runtime; missing environments can be installed by two startup scripts that run on every container start:

- `init/root.sh`: runs as root, for APT packages, third-party repositories, and other system-level dependencies
- `init/user.sh`: runs as the unprivileged `zcode` user with `HOME=/data/home`, for user-level toolchains

## Updating ZCode

Every newly created container automatically downloads the latest ZCode release. To update, recreate the container:

```bash
docker compose up -d --force-recreate
```


## Build arguments

`APT_MIRROR_HOST`: Debian APT mirror hostname. Set it when you want to use another mirror.

```bash
APT_MIRROR_HOST=mirrors.aliyun.com docker compose build --no-cache
```

`S6_OVERLAY_VERSION`: pinned s6-overlay release used by the image build. The build downloads both release tarballs and verifies them against the checksum files published with that release.

## Disclaimer

This is an unofficial deployment configuration. ZCode and its installer are copyrighted by their official owners. Use this project in accordance with ZCode's terms of service.
