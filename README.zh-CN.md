# ZCode Headless Server

非官方 Docker 包装，用于在无显示器服务器上长期运行 ZCode Desktop，承接 24 小时开发任务，不需要长时间打开自己的电脑。

## 功能

- 自动从 ZCode 官网获取最新 Linux x64 `.deb` 安装包
- Xvfb 虚拟显示
- Openbox 窗口管理器
- 支持 ZCode 官方远程控制
- x11vnc + noVNC 备用网页控制
- 登录态、配置、任务状态持久化
- 本地工作区挂载

## 要求

- Linux x64 / amd64
- Docker Engine
- Docker Compose v2

## 使用流程

先自行安装 Docker Engine 和 Docker Compose v2。

```bash
git clone https://github.com/hyizhou/zcode-docker.git
cd zcode-docker
docker compose up -d --build
```

1. 在浏览器访问：

```text
http://<服务器IP>:6080/
```

2. 使用 `VNC_PASSWORD` 指定的密码进入桌面。

3. 登录 ZCode 账户。
4. 使用 ZCode 官方远程控制功能连接该设备。
5. 在 ZCode 中添加项目。
6. 之后通过 ZCode 官方远程控制进行开发。
7. 关闭浏览器；完成 ZCode 官方远程控制配对后，通过宿主机防火墙、Docker 防火墙链或云安全组屏蔽 `6080` 端口，需要 VNC 备用时再临时放行。

首次使用前修改 `docker-compose.yml` 中的 `VNC_PASSWORD`：

```yaml
VNC_PASSWORD: "change-me"
```

## 数据保存

数据保存位置：

- `/data`：保存登录态、配置、会话和日志
- `/workspace`：提供给 ZCode 使用的工作区目录

执行以下操作不会丢登录态：

```bash
docker compose restart
docker compose down
docker compose up -d
```

只有执行 `down -v` 或手动删除 named volume 才会清除 `/data`。

## 夜间免费时段

GLM Coding Plan 付费套餐用户在 ZCode 中使用 GLM-5.3-Flash 时，2026 年 9 月 3 日至 9 月 20 日每天北京时间 23:00 至次日 09:00 额度消耗为 0，含周末和公共假日。详情见[官方活动说明](https://docs.bigmodel.cn/cn/coding-plan/notice/event-glm-5.3-flash)。

## 更新 ZCode

构建时会解析官网最新 Linux x64 安装包地址。由于 Docker 会缓存构建层，强制检查最新版本时使用：

```bash
docker compose build --no-cache
docker compose up -d
```

## 构建变量

`APT_MIRROR_HOST`：Debian APT 镜像域名；需要更换镜像源时指定。

```bash
APT_MIRROR_HOST=mirrors.aliyun.com docker compose build --no-cache
```

## 常用命令

```bash
docker compose logs -f
docker compose ps
docker stats zcode-webvnc
docker compose exec zcode bash
docker compose restart
docker compose down
```

## 安全注意事项

- 必须修改默认 VNC 密码。
- `/data` 中包含登录凭据和会话数据，不要随意共享。
- 不建议把 `6080` 直接暴露到公网；公网访问建议放在反向代理、VPN 或防火墙之后，并启用 HTTPS。

## 声明

这是非官方部署配置。ZCode 及其安装包的版权归官方所有，使用时请遵守 ZCode 官方服务条款。
