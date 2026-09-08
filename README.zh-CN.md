[English](README.md) | [简体中文](README.zh-CN.md)

# ZCode Headless Server

非官方 Docker 包装，用于在无显示器服务器上长期运行 ZCode Desktop，承接 24 小时开发任务，不需要长时间打开自己的电脑。

> GLM Coding Plan 付费套餐用户在 ZCode 中使用 GLM-5.3-Flash 时，2026 年 9 月 3 日至 9 月 20 日每天北京时间 23:00 至次日 09:00 额度消耗为 0，含周末和公共假日。详情见[官方活动说明](https://docs.bigmodel.cn/cn/coding-plan/notice/event-glm-5.3-flash)。

## 要求

- Linux x64 / amd64
- Docker Engine
- Docker Compose v2

## 使用流程

```bash
git clone https://github.com/hyizhou/zcode-docker.git
cd zcode-docker
cp docker-compose.example.yml docker-compose.yml
mkdir -p workspace   # 映射进容器的目录，可作为 ZCode 工作区，ZCode 也可使用其他路径
                     # 须在启动前创建，否则 Docker 代建的属主是 root；挂载路径可在 compose 中更换
docker compose up -d --build
```

1. 在浏览器访问：

```text
http://<服务器IP>:6080/
```

2. 使用 `VNC_PASSWORD` 指定的密码进入桌面；建议在 `docker-compose.yml` 中修改默认密码。

3. 登录 ZCode 并完成官方远程控制配对，添加项目到 ZCode 中。
4. 关闭浏览器。完成配对后，通过宿主机防火墙、Docker 防火墙链或云安全组屏蔽 `6080` 端口，或设置 `VNC_ENABLED=0` 并重建容器以停用 VNC 服务；需要备用 VNC 时再临时放行端口。

## 环境变量

在 `docker-compose.yml` 的 `environment` 段设置，或写在 Compose 文件旁的 `.env` 文件里（已被 Git 忽略）：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `VNC_PASSWORD` | `zcode123` | 备用网页 VNC 的密码；首次使用前必须修改。 |
| `VNC_ENABLED` | `1` | 设为 `0` 时备用 VNC 服务保持停止，`6080` 端口无进程监听，适合完成官方远程控制配对后使用。ZCode 及远程控制不受影响。 |
| `EXTRA_APT_PACKAGES` | 空 | 每次容器启动时安装的 Debian 软件包，空格或逗号分隔；以 root 安装，ZCode 仍以非特权用户 `zcode` 运行。 |

环境变量在容器创建时固化；修改后执行 `docker compose up -d` 重建容器生效。

## 数据保存

数据保存位置：

- `/data`：保存登录态、配置、会话和日志
- `/workspace`：映射进容器的目录，可作为 ZCode 的工作区；ZCode 也可以使用其他路径

## 自定义启动脚本

镜像只内置基础运行环境；缺少的环境可以用两个启动脚本在每次容器启动时安装：

- `init/root.sh`：以 root 运行，用于 APT 包、第三方软件源等系统级依赖
- `init/user.sh`：以非特权用户 `zcode`、`HOME=/data/home` 运行，用于用户级工具链

## 更新 ZCode

每次容器创建时都会自动下载最新的 ZCode 版本。需要更新时，重建容器：

```bash
docker compose up -d --force-recreate
```


## 构建参数

`APT_MIRROR_HOST`：Debian APT 镜像域名；需要更换镜像源时指定。

```bash
APT_MIRROR_HOST=mirrors.aliyun.com docker compose build --no-cache
```

`S6_OVERLAY_VERSION`：镜像构建使用的固定 s6-overlay 版本。构建时会下载该版本的两个发布包，并使用官方随版本发布的校验文件验证。

## 声明

这是非官方部署配置。ZCode 及其安装包的版权归官方所有，使用时请遵守 ZCode 官方服务条款。
