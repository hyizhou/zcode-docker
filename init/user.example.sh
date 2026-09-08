#!/usr/bin/env bash
# 本文件以 zcode 用户（uid 1000）在每次容器启动时执行，HOME=/data/home。
# This file runs as the zcode user (uid 1000) on every container start, with HOME=/data/home.
# 适合：安装用户级工具链（如 uv、pipx）或写入用户目录的配置。
# Suitable for user-level toolchains such as uv or pipx, or user-directory configuration.
# 说明：/data 在持久卷中，已安装内容跨容器重建保留，建议先判断再安装。
# Note: /data is in the persistent volume, so installed content survives container recreation.
# 规则：非零退出会终止容器启动；无需可执行权限。
# Rule: a non-zero exit stops container startup; no executable bit is required.

# 在这里添加你的命令
# Add your commands here
