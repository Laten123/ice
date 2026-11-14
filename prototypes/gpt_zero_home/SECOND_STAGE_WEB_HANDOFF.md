# 第二阶段：手机显示真实 Godot Web 画面（深寻执行）

**已确认的第一阶段结果**（拿铁转发深寻的手机测试报告）：
- 安卓浏览器（VPN 全局）访问临时 `trycloudflare.com/public/world`，取得 `path-test` 虚构居民公开 JSON，`zone=door`、`activity=idle`。
- 上游 8200 保持本机绑定，隧道只指向 8211 预览服务；私有 API 被挡，`/public/world` 没有居民 token。
- 这些是**深寻转报的实测结果**。ChatGPT 没有直接访问服务器，不以此断言 Godot Web 页面已通过。

## 决定

**现在立即开始第二阶段，仅测试虚构居民。** 不要求拿铁买域名、注册 Cloudflare、关闭 TLS 校验或修改生产 8080。现有 Quick Tunnel 可继续使用；如果因进程重启换了随机域名，就提供**新的**地址，不依赖旧网址永远有效。

### 1. 在服务器隔离目录准备当前测试分支

请先确保工作树是 `prototype/ai-first-home` 的最新代码，**不要覆盖生产仓库/主分支**。在独立 Godot 工程目录 `prototypes/gpt_zero_home` 执行：

```bash
bash tests/export_staging_web.sh
```

此脚本：
- 复制**独立临时工程**到随机 `/tmp/fantasia-staging-web.XXXXXXXX/project`；
- 只在临时副本把入口切换到 `res://scenes/public_viewer_staging.tscn`；
- 只在副本里生成 `Web` 导出预设（**线程支持关闭**）；
- 要求现成的 **Godot 4.6.3 Web 导出模板**，若缺失**明确失败**而不是暗中修改全局/生产环境；
- 导出到同一临时目录的 `web/index.html`，检查 `.js/.wasm/.pck`；
- 最后打印 `[WEB_DIR] /tmp/fantasia-staging-web.XXXXXXXX/web`。

*如果 Web 模板缺失*，先在隔离环境安装与 Godot 二进制**完全相同版本**的导出模板，或报告失败日志；禁止直接复用版本不符的模板。不要修改 Godot 正式工程 `project.godot` 或把 `export_presets.cfg` 写进生产目录。Godot 的官方 CLI 文档要求先创建预设和安装对应的导出模板。

### 2. 预览服务改为同时提供 Web 静态文件与公开快照

保持 P1 8200 仅 `127.0.0.1`、8211 也仅 `127.0.0.1`。如已经有旧的 8211 预览进程，**只停止这个已确认的旧预览进程**，不能影响 P1 或生产进程。

启动：

```bash
python3 tests/preview_public_server.py \
  --test-resident-id path-test \
  --web-dir "/tmp/fantasia-staging-web.XXXXXXXX/web"
```

上面 XXXXXX **不是实际路径**，务必替换为 `export_staging_web.sh` 打印的 `[WEB_DIR]`。

请先本机验证：`curl -fsS http://127.0.0.1:8211/health`、`curl -fsS http://127.0.0.1:8211/public/world`、`curl -fsS http://127.0.0.1:8211/ | head -c 120`。再次检查私有 `/intent`、`/admin`、`/observation` 只返回 404，非 GET 返回 405。禁止静态目录包含任何数据库、密钥、日志或居民记录。

若 Quick Tunnel 仍运行并指向 8211，可以继续用**同一个临时 HTTPS 地址**；如果隧道停止需重建，地址可能变化：

```bash
cloudflared tunnel --url http://127.0.0.1:8211
```

**不要使用 `--url http://127.0.0.1:8200`。**

### 3. 手机端观察目标

拿铁的安卓浏览器可使用之前实测有效的 VPN 全局模式，打开临时 HTTPS 地址**根路径 `/`**（不是 `/public/world`）。

需要分开核验三件事：

A. Godot 加载：是否出现初代家园主画面；手机横/竖屏调整布局、上午/黄昏观察按钮可点击；WebGL/WASM 能否初始化。

B. 只读世界快照：`path-test` 已明确授权公开时，观察器应呈现与服务器 JSON 相同的名字、地点、活动状态；撤销公开应把虚构居民从画面移除。没有允许访问任何真实居民。

C. 服务器权威动作：虚构居民通过 P1 自己的认证测试工具提交移动（**不经浏览器**）。`GET /public/world` 的 `revision` 变化，Godot 观察器在下一次获取时更新为服务器报告的位置、活动。浏览器不出现移动操纵按钮、不发送 `/intent` 请求。

保留真实证据：服务器 **脱敏**的状态日志、`/public/world` 的公开 JSON、手机 Web 页面的截图及出现错误时的浏览器报错。不回传 token、管理员密钥、原始 Cookie 或私密内存。

### 4. 已知限制与停机

- 当前 Python `progress` 为 `0.0`；Godot 使用权威 `zone` 跳点。**不宣称平滑道路动画已通过**。
- SVG 场景仍是早期视觉样板，不代表最终美术完成。
- Godot 的实际 Web 导出依赖 Godot 4.6.3 官方模板；真实 Android 浏览器运行和流畅度**必须以手机实测为准**。
- 预览服务和隧道都只作临时前台进程，短测完成后由深寻按对应 PID **分别停止**，避免影响 8200 P1 数据库、8080 正式项目或其他服务。
- Cloudflare Quick Tunnel 地址是临时公开入口。测试完关闭，不用于发布任何长期居民信息。

### 5. 验收口径

只有 **Godot Web 页面成功加载 + 浏览器读到服务端公开快照 + 页面随服务端动作变化**，才宣布第二阶段通过。第一阶段的 JSON 成功不是第二阶段的完成凭据。

**责任人**：深寻负责隔离服务器和 Web 导出/测试通道；ChatGPT 负责 Godot 观察器协议及可视位置映射；拿铁负责在手机端观察体验，无须运维操作。
