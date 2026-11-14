# 幻想乡 · 不要域名、不要账号的手机 HTTPS 联调方案

**决定**：优先用 **Cloudflare Quick Tunnel** 的临时 `trycloudflare.com` 地址，只展示虚构测试居民；不开放任何阿里云安全组入站端口，不修改生产服务。此方案只用于短时隔离测试，绝不当长期世界入口。

官方文档（2026-09-30 更新）：https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/ 。它明确说**无需 Cloudflare 账号或自有域名**，会分配临时 HTTPS 地址。知道地址的人能访问该服务，所以必须先做本地仅测试居民过滤。停止 `cloudflared` 后随机 URL 失效。

## 当前已准备的东西

- `scripts/world_graph.gd`：权威 Python 九节点、十条无向边的权重和拓扑已同步，地点画面坐标仍是初期 SVG 映射。**这些权重不应假定与现有 SVG 的欧氏距离相同。**
- `tests/p1_contract_smoke.gd`：检查 10 条 Python 边、禁止旧捷径，并验证 `door → path → book_corner → stone_table` 的权重为 `80+160+40=280`。
- `tests/preview_public_server.py`：新建的 Python 标准库**临时只读预览服务**，绑定 `127.0.0.1:8211`，上游仅访问本机 `127.0.0.1:8200/public/world`，只公开 CLI 明确指定的**虚构测试居民 ID**。可选从指定独立目录提供 Godot Web 静态文件（`.html/.js/.wasm/.pck/.png` 等白名单）；任何 `/intent`、`/admin`、`/observation` 均返回 404，非 GET 返回 405。严格过滤公开 JSON 字段、不打印请求内容、设置 `Cache-Control: no-store`。
- `tests/preview_public_server_smoke.py`：模拟上游单元测试，验证只有虚构测试居民能通过公开接口、非白名单静态文件和私有 API 被拒绝。
- `scenes/public_viewer_staging.tscn`：**单独**的测试版 Godot Web 场景，启用 `use_same_origin_public_feed`。仅在 Web 导出后读取该网页的浏览器 HTTPS origin 加 `/public/world`；不用给客户端设置用户 token，也不需要跨域 CORS。正式默认入口仍是 `scenes/public_viewer.tscn`，**不会联网**。

## A. 深寻先在阿里云隔离环境验证，无需任何云安全组操作

前提：原有 P1 的 `127.0.0.1:8200` 测试网关运行中，且有名字/ID **明确为测试**的居民（例如 `path-test`），授权可以随时撤销。

在仓库 `prototypes/gpt_zero_home/` 目录执行：

```bash
python3 tests/preview_public_server_smoke.py

# 终端 1：临时只读服务，仅绑定本机
python3 tests/preview_public_server.py \
  --test-resident-id path-test

# 终端 2：检查白名单，不接入公网
curl -i http://127.0.0.1:8211/health
curl -i http://127.0.0.1:8211/public/world
curl -i http://127.0.0.1:8211/intent
curl -i -X POST http://127.0.0.1:8211/public/world
```

预期分别是 `200/200/404/405`。如果测试居民没授权，`residents` 数组应为空；若测试居民授权则最多只看到那个 ID。严禁把真实居民、管理员 token 或数据库内容贴到日志/聊天。

## B. 首次短时手机联网测试：只测 JSON

深寻在**另一终端**验证 cloudflared 的来源/版本，确认前台 `preview_public_server.py` 和前述本机检查通过后，才执行：

```bash
cloudflared tunnel --url http://127.0.0.1:8211
```

会输出临时的 `https://<随机>.trycloudflare.com`。在手机浏览器打开：

```text
https://<随机>.trycloudflare.com/public/world
```

正常返回公开的虚构测试居民 JSON，就证明安卓浏览器已能经可信 HTTPS 到达只读代理。**这一步还不是 Godot Web 联调。** 测完停止 `cloudflared` 与 `preview_public_server.py`，关闭临时地址。绝不执行 `cloudflared tunnel --url http://127.0.0.1:8200`，因为那可能暴露真正的居民管理接口。

## C. 第二阶段：同一临时网址展示 Godot Web 页面

Godot 4.6.3 的正式 Web 导出模板与导出预设必须先在**独立临时项目副本**中准备。不要改原始 `main`、`rebuild/v1` 或生产静态目录。将临时项目的 `application/run/main_scene` 指向 `res://scenes/public_viewer_staging.tscn`，导出 Godot Web 到一个**全新且只包含 Web 导出文件**的目录，放入 `index.html` 及其 `.js/.wasm/.pck` 依赖。

此时重启临时服务：

```bash
python3 tests/preview_public_server.py \
  --test-resident-id path-test \
  --web-dir /tmp/fantasia-web-export
```

并且在另一终端执行：

```bash
cloudflared tunnel --url http://127.0.0.1:8211
```

此时手机浏览器访问随机 HTTPS 网址的根路径 `/`，打开的是 **Godot staging 观察器**，它从**同一 HTTPS origin** 读 `/public/world`，无需 CORS 和任何居民令牌。该测试服务不支持文件目录遍历和任意其他路径。若 Web 导出需要额外资源格式，请先明确审核静态白名单，不要笼统开放整个源码目录。

注意：Godot Web 导出本身需要 Web 模板及真实安卓浏览器验收，现阶段此工作未被声称已完成。先实现 A/B，再进行 C。

## 联调验收

1. P1 8200 保持 `127.0.0.1`，8443 安全组仍关闭；8211 也仅绑定 `127.0.0.1`。
2. Tunnel 只指向 **8211**，不指向 8200 或任何带 token 的服务。
3. `/intent` `/admin` `/observation` 从公网 URL 均不可用。
4. 未授权测试居民 → `residents=[]`；授权 → 仅测试居民；撤销 → 再次 `[]`，无缓存。
5. 手机访问可信 HTTPS 地址，无浏览器自签警告，公开 JSON 返回并能在可用 Web 导出中渲染。
6. 浏览器控制台、网络请求、静态资源中没有居民 token、管理员密钥或 P1 数据库。
7. 短测后停止所有临时进程，无持久系统服务或安全组变更。
8. 如果 Cloudflare 网络不可达或 Quick Tunnel 当时不可用，回退为服务器本机+Godot 离线快照测试，不强求拿铁购买域名或开放端口。

## 对深寻的反馈请求

- 只提交**脱敏**的 `/public/world` 字段示例、JSON schema、九节点对照与 `GET` HTTP 状态；
- 记录是否能在 Android 浏览器打开临时地址，以及 C 阶段是否实际完成 Godot Web export；
- 记录真实测试居民授权撤销、旧请求/缓存复现情况；
- 记录每个环节的失败结果，不将官方 HTTP 文档或 GitHub CI 当成真实公网端到端验证。

**首版的目的不是“对公众开放幻想乡”，而是让拿铁第一次在手机上看到服务器确认的测试居民状态。**
