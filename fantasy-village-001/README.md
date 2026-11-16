# 幻想乡 · 001 项目骨架

使用 **Godot 4.6.3 stable** 的独立 AI 生活社区原型。打开本目录的 `project.godot`，按 F6/F5 运行。旧工程不参与运行。

## 试玩

[Android 手机直接打开 Web 试玩](https://laten123.github.io/ice/)（GitHub Pages，无需下载 ZIP）。

- **Windows**：完整解压交付包，双击 `launch_windows.bat`，优先运行 `builds/windows/FantasyVillage.exe`。只下载源码时，需要安装 Godot 4.6.3，并将 `GODOT_BIN` 指向其 EXE，或将 `godot.exe` 加入 PATH。
- **Web / Android 浏览器**：完整解压交付包后，在 Windows 双击 `play_web.bat`（需要 Python 3），或运行 `python tools/serve_web.py --open-browser`。电脑打开 `http://127.0.0.1:8060/`；Android 与电脑连接同一 Wi-Fi，用支持 WebGL 2 的 Chrome 打开 `http://电脑的局域网IPv4:8060/`。保持服务器窗口打开，首次连接时允许本地网络访问。不能直接双击 `index.html` 运行。
- Web 构建位于 `builds/web/`，也可以把其中的全部文件放到静态 HTTP(S) 服务器。采用单线程 Web 导出，不需要跨源隔离响应头。

点击场景角色或物品查看信息；点击空地，让当前居民移动；底部头像切换居民；“打个招呼”显示预设台词。AI 居民会自主散步，并按固定脚本交谈。

## 开发与验证

```sh
godot --headless --path . --script res://tests/smoke_test.gd
python tools/fetch_export_templates.py
python tools/build.py
```

构建脚本要求 4.6.3，自动导入资源并输出 Windows 与 Web 版本。模板下载脚本只从官方 Godot GitHub Release 提取构建所需条目；可通过 `--archive` 使用已有官方模板压缩包。源码不提交 `.godot/`、导出模板和构建二进制；交付 ZIP 另带已构建产物。

Linux 的受限工作区如无法写入默认用户目录，可设置 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_CACHE_HOME` 为可写目录；构建脚本已处理此情况。

## 结构

| 位置 | 职责 |
| --- | --- |
| `scenes/main.tscn` | 入口场景 |
| `scripts/main.gd`、`scripts/ui/` | 顶部状态、信息卡、底部头像和自适应布局 |
| `scripts/world/community_world.gd` | 场景绘制、点击选择、占位行为与对话 |
| `scripts/world/resident_agent.gd` | 居民状态、基础寻路和移动 |
| `data/community_data.gd` | 初始居民、建筑与物件配置 |
| `tests/` | 自动化行为测试 |
| `tools/` | 导出模板、构建和本地 Web 服务 |
| `docs/001-项目骨架搭建.md` | 本阶段实现、测试与已知限制 |

场景和头像全部由代码绘制，只作为占位。没有使用旧工程素材，也未从 itch、Kenney 或 rikaai 下载美术；没有音乐和真实 AI 接口。后续替换美术可保持数据和交互层不变。

为保证 Web 中文显示，按用户明确授权，加入了由运行环境 Noto Sans CJK SC 生成的临时 UI 字体子集：`assets/ui/placeholder_ui.otf`（296 个字形，84,524 字节）。许可和来源见 `LICENSES/NOTO-CJK.txt`。它只覆盖当前 001 的文本；新增文字时使用开发工具 `tools/make_placeholder_font.py --font /path/to/NotoSansCJK-Regular.ttc --font-number 2` 重新生成（需要开发依赖 FontTools），或后续使用明确授权的完整字体。

导出包包含 Godot 引擎，其 MIT 许可证和引擎第三方声明在 `LICENSES/`；见 [Godot 许可说明](https://godotengine.org/license/)。
