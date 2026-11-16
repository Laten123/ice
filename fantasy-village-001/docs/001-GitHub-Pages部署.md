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

Actions 运行、公开地址和线上 HTTPS 验收的准确结果将在发布后填入。未发布前不将预期地址称为可用试玩链接。测试使用 Chromium 的手机视口和触摸模拟，不替代 Android 实体设备测试。
