# 001-GitHub-Pages部署

本次只增加部署流程，不修改游戏功能、美术、字体、场景或旧工程。

## 来源和改动位置

- 仓库：`Laten123/ice`。
- 唯一构建分支：`feature/001-project-skeleton`。
- 唯一工程目录：`fantasy-village-001/`。
- 初始来源提交：`26562e961598f5b6264daab6073070536a98dcd6`。
- `.github/workflows/deploy-fantasy-village-001.yml`：自动构建、测试和 Pages 发布。
- `.github/scripts/prepare-godot-web.py`：下载官方 Godot 4.6.3，校验引擎和模板，只提取 Web 构建需要的模板。
- `.github/scripts/check-pages-artifact.py`：检查单线程产物、相对资源路径和 HTTP MIME 类型。
- `.github/scripts/check-live-pages.py`：等待公开 HTTPS 页面，验证资源响应、导出大小和 PCK 完整性，生成 JSON 验收记录；不进入游戏运行包。

默认分支 `main` 和旧工程不参与构建，也不会被替换。二进制、导出模板、缓存和测试截图通过 Actions 临时产物保存，不提交到源码。无需个人访问令牌或新的仓库密钥。

## 运行过程

1. 向指定分支推送工程或本部署配置的变更，触发工作流。
2. 检出当前分支提交，校验并准备 Godot 4.6.3。
3. 调用原工程的 `tools/build.py --target web`，运行原有 41 项行为测试。
4. 检查 Web 相对资源路径、产物完整性、单线程标记以及 MIME 类型。
5. 只上传 `fantasy-village-001/builds/web/`，附带运行时与字体许可证，然后发布到 GitHub Pages。
6. 在 GitHub 托管运行器上检查公开 HTTPS 资源，并运行桌面、手机竖屏和手机横屏浏览器测试，保留截图与控制台输出。

工作流保留手动触发声明，但 GitHub 只有在默认分支包含该工作流时才显示手动运行按钮。本次不为此修改 `main`；首次及之后的发布使用指定分支的推送触发。

## 需要事先批准的设置

用户要求在更改 Pages 设置或权限前征得同意。发布流程准备阶段不调整以下设置：

- 仓库 Settings → Pages → Build and deployment → Source 必须为 **GitHub Actions**。
- 仅部署任务使用 `pages: write` 和 `id-token: write`；构建和验收任务只有 `contents: read`。
- `github-pages` 部署环境必须允许指定功能分支；如已有审批人或其他保护规则，保留并遵守，不自动删除或放宽。

本连接没有 Pages 设置写入接口；如需要由仓库所有者在手机 GitHub 网页设置，可使用仓库的 Settings → Pages，无需下载 ZIP。

## 测试记录

部署前已经完成：

- 从指定分支的来源提交检出独立验证副本，16 个游戏相关文件逐字节一致，无游戏改动。
- 官方 Godot 4.6.3 ZIP 的 SHA-512、两份 Web 模板的 SHA-256 和 ZIP CRC 校验通过。
- 使用新下载引擎调用原有 Web 构建工具，退出码 0。
- 原有行为测试 41/41 通过。
- Pages 风格子路径下的 HTTP/MIME 检查通过；桌面 1280×900、手机竖屏 390×844、横屏 844×390 均通过浏览器测试，控制台无错误，中文正常显示，点击与触摸更新信息卡和移动状态。
- 工作流结构、分支触发、固定 Actions 提交号、任务权限隔离与 Bash 语法检查通过。

线上部署和验收已于 2026-11-16 完成。测试使用 Chromium 的手机视口和触摸模拟，不替代 Android 实体设备测试。

首次 GitHub 校验发现任务级 `env` 不允许使用 `runner.temp`，因此任务尚未启动。已将三项 XDG 路径改为允许的 `github.workspace` 下的临时构建目录。补充使用官方 actionlint 1.7.12 校验，退出码 0、无诊断；在修正后的目录设置下重新运行原有 41 项测试，全部通过。该修复仅影响 CI 临时目录。

用户已明确批准发布任务的 Pages/OIDC 权限，以及在保留现有审核规则的前提下允许指定分支，并确认 Pages 来源已切换为 GitHub Actions。运行 `43806080531` 的云端构建成功：官方依赖校验、Web 导出、41/41 行为测试、HTTP 子路径检查及 Pages 产物上传全部通过。发布启动前曾被既有 `github-pages` 环境分支规则拒绝。仓库所有者随后确认已添加准确的 `feature/001-project-skeleton` 分支规则并保留原有规则；重试失败的发布任务后成功。未通过另建环境或取消保护规则绕过此限制。


## 实际发布和线上验收结果

- Android 手机直接打开：**https://laten123.github.io/ice/**，无需 ZIP 或本地服务器。
- 发布源提交：`51aa268771924b87bcf950232b565a7d7a77736a`。
- Actions 运行：[43806080531](https://github.com/Laten123/ice/actions/runs/43806080531)，第二次尝试；`build`、`deploy`、`verify-live` 全部成功。重试沿用原成功构建，没有更改游戏。
- 构建来自指定分支的 `fantasy-village-001/`；引擎为官方 Godot 4.6.3。

| 检查项 | 结果 |
| --- | --- |
| HTML HTTPS GET | HTTP 200，`text/html` |
| `index.js` | HTTP 200，`application/javascript` |
| `index.wasm` | HTTP 200，`application/wasm`，37,700,666 字节，大小匹配导出元数据 |
| `index.pck` | HTTP 200，`application/octet-stream`，108,668 字节；完整下载长度校验通过 |
| 两个 audio worklet | HTTP 200，`application/javascript`；仅引擎运行时文件，无新增音乐 |
| 线上 PCK SHA256 | `da1e56e0a36642c0d6b110c5b444d05d62f874fc782e4575b3e00542564d7ab1` |
| 原有行为测试 | 41/41 通过 |
| 线上桌面 Chromium | 1280×900，通过 |
| 线上手机竖屏模拟 | 390×844，通过 |
| 线上手机横屏模拟 | 844×390，通过 |
| 点击和触摸 | 房屋信息卡更新、头像切换及点击空地移动通过；截图可见选中 AI 的“正在散步”状态 |
| 中文 | 已检查本次线上测试生成的实际截图，标题、角色名、信息卡、台词均正常显示 |
| 浏览器与引擎错误 | 三种视口均 `errors: []`，无页面溢出 |

线上 JSON 验收摘要保存在 `docs/test-results/001-pages-live.json`。截图、完整控制台记录和 HTTP 报告上传为 Actions 产物 `fantasy-village-001-live-verification`（保留 3 天）；公开运行日志包含永久可核对的状态和测试结果。

本次源码改动仅为部署工作流、CI 验证助手、部署记录及 README 试玩入口。未修改场景、脚本、美术、字体、旧工程或 `main`。没有提交个人密钥、引擎、导出模板、Windows/Web 构建二进制或缓存。最后的记录提交使用 `[skip ci]`，只补充已完成的测试结果，避免对同一游戏产物重复部署。
