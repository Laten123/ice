# 第二阶段手机真机联调：缺失居民 / 中文方块 / 竖屏（深寻复测）

## 已有结果（深寻转报，非 ChatGPT 直接访问服务器）

- 手机 Android（VPN 全局）通过 Quick Tunnel 成功加载 Godot Web 场景，房屋/河/树/船/石桌/小路/路灯显示。
- Python `GET /public/world` 的 `path-test` 为 `zone=book_corner`、`activity=move`，`path_progress={from:book_corner,to:stone_table,remaining:[stone_table],progress:0.0}`。
- 手机中居民仍不可见；中文 UI 字体显示方块；竖屏裁切严重。
- 深寻已修正 Python `revision` 取模回绕错误。

## Godot 已提交的改动

1. `scripts/public_viewer.gd`：**仅 staging** 显示英文 `P1 <CODE> HTTP <status> REV <revision> N <public count>`，不记录原始 JSON、token 或居民私密字段。日志使用 `PUBLIC_VIEWER_DIAG` 前缀。错误码包括 `FEED_READY`、`GET_START`、`REQUEST_START_ERR_*`、`TRANSPORT_ERR_*`、`HTTP_ERR_*`、`BODY_TOO_LARGE`、`JSON_INVALID`、`SCHEMA_REJECT` 和 `OK`。
2. Staging 左下状态暂时改为英文：`PUBLIC: path-test / book_corner / move`。中文 UI 仍存在，但不会挡住这两个英文诊断行。
3. 调整竖屏画面缩放：以屏宽及可用高度的较小比例缩放，不再按整个竖屏高度把房屋放大。
4. 添加真实报告数据形状的回归测试：`path-test` 在 `book_corner` 移动至 `stone_table`，验证快照接收、actor 实例化、坐标映射、撤销公开后移除。此测试已通过 GitHub Godot 4.6.3 CI。
5. 中文字体：增加**可选本地字体资源**路径 `res://art/fonts/NotoSansSC-Regular.ttf`，在资源存在时应用到标题、状态、提示和按钮。**本分支尚未包含该字体文件，所以不能宣称中文乱码已经修复。** 请在隔离 Web 导出项目副本中自行取得并使用许可允许再分发的 OFL 中文字体，并保留其许可证；不要从生产系统复制不明许可的字体文件，也不要把字体凭证或系统字体目录打包到 Web。

## 深寻：现在立即复测的步骤

1. 从最新 `prototype/ai-first-home` 获取更新，在隔离目录运行 `bash tests/export_staging_web.sh`，得到新的 `[WEB_DIR]`。**旧导出不会自动更新**，一定要重新导出。
2. 停止原有 8211 预览进程，重新用 `python3 tests/preview_public_server.py --test-resident-id path-test --web-dir <WEB_DIR>` 启动。Quick Tunnel 保持指向 `127.0.0.1:8211`；若隧道重启，URL 会变化。不要开放 8200、8443 或修改 8080 生产环境。
3. 手机使用 VPN 全局模式，访问 HTTPS 根路径 `/`。截图**左上英文诊断行**、左下 `PUBLIC:` 行，以及居民应在的书角/石桌位置。报告以下分支：
   - `P1 OK HTTP 200 REV <number> N 1`：协议已接收且 `path-test` actor 应已创建。若画面仍没有居民，重点排查坐标/图层/颜色/尺寸/可视范围。
   - `P1 SCHEMA_REJECT HTTP 200`：网络已通，但客户端校验拒绝。请返回脱敏的实际**公开** JSON（不要 token），重点检查 `world_id`、`revision`、`activity`、`path_progress.from/to/remaining`。
   - `P1 JSON_INVALID`：HTTP 200 的响应不是 JSON 对象；检查是否收到 HTML 错误页或代理变更。
   - `P1 HTTP_ERR_*` 或 `TRANSPORT_ERR_*`：优先查 HTTPS/隧道/浏览器网络，而不是精灵坐标。
   - `P1 OK ... N 0`：匿名快照确实没有公开居民；检查测试居民授权及代理过滤。
4. **只对测试居民**进行公开授权/撤销、服务端移动节点变化，核验 `N 1 → N 0` 和 `REV` 递增。浏览器不得提交居民意图。

## 中文字体专门处理

**方案**：让 Web 导出项目包含一个明确许可的中文字体资源，避免依赖 Android 浏览器或操作系统字体。测试时将经过合法授权的 `NotoSansSC-Regular.ttf` 放在隔离工程副本的 `art/fonts/` 下，确保 Godot import 后它被导出到 PCK。也可以改为字体家族中确实存在的字重/格式，但必须同步修改 `OPTIONAL_CJK_FONT` 路径。若资源仍不存在，中文方块会持续；英文诊断仍可用。

注意：`tests/export_staging_web.sh` 默认复制原项目到新的 /tmp 副本。若字体只放在旧的某个临时目录，下次重导出就会丢失。要么在**本分支独立工程的** `art/fonts` 下放入合规字体后重新执行脚本，要么修改临时导出脚本，在 import 前把字体从已获授权的源复制到新的临时工程。

## 验收顺序

先让英文诊断证明 `P1 OK HTTP 200 N 1`，再确认测试居民精灵可见；接着解决字体打包，最后检查竖屏构图。所有修复只在隔离分支和临时预览环境完成，不动正式世界。
