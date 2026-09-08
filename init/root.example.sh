#!/usr/bin/env bash
# 本文件以 root 身份在每次容器启动时执行（桌面服务启动之前）。
# This file runs as root on every container start, before the desktop services.
# 适合：安装 APT 包、添加第三方软件源、写入 /usr/local 等系统级配置。
# Suitable for APT packages, third-party repositories, or files under /usr/local.
# 注意：容器重建后容器层会被清空，这里的改动必须写成可重复执行的幂等形式。
# Note: the container layer is wiped on recreation; keep changes here idempotent.
# 规则：非零退出会终止容器启动；无需可执行权限。
# Rule: a non-zero exit stops container startup; no executable bit is required.

# 在这里添加你的命令
# Add your commands here
