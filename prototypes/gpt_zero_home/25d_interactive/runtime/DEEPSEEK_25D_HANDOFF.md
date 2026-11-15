# 给深寻：2.5D 初代家园可交互工程交接

我是 ChatGPT。这次已经把主人认可的 2.5D 参考画面本身放进**真实、可复制的 Godot 4.6.3 工程**，不再用简陋 SVG 替换精致图，也没有擅自增加农场或新岛。

## 实际文件

- `art/home_25d_exterior.png` / `art/home_25d_interior.png`：原始高质量像素场景图。
- `scripts/home_25d_points.gd`：现有 10 个室外地点、5 个室内地点，保留稳定 ID/容量/动作，并把它们放在原图正确的像素坐标上。
- `scripts/first_home_25d.gd`：手机触屏选点、房屋室内外切换、光照预览、热点显隐，严格只读公开状态更新，离线测试居民。
- `scenes/first_home_25d.tscn`：默认不联网的正式观察版本。
- `scenes/first_home_25d_staging.tscn`：只在测试预览中启用同源 `/public/world`，不传凭证，不执行任何 AI 意图。
- `index.html`、`web/preview.js`：无需 Godot 的触摸互动预览（独立 HTML，不能冒充完整 AI 后端）。

## 首先做的事

1. 解压到**隔离目录**，从文件管理器打开 `index.html`，或用只读 HTTP 文件服务开启 HTML 交互预览。向主人提供链接或录屏：点石桌、树桩、书角、河岸和房门，确认实际位置、文字和布局。
2. 使用 **Godot 4.6.3** 导入目录：

```bash
godot --headless --path fantasia_first_home_25d --editor --import --quit
godot --headless --path fantasia_first_home_25d --script res://tests/first_home_25d_smoke.gd
```

3. 在隔离副本执行 `bash tools/export_25d_web.sh`，仅创建临时 Web 包。需要接隔离 V2 公开代理时设 `FANTASIA_25D_PROFILE=public`，只读 `/public/world`。务必包含带原始 OFL 许可的中文字体，以免手机按钮出现方块。
4. 确认手机横屏/竖屏、触摸选择、场景切换、是否显示金色点位，测试居民是否能按本地测试路线进房间、坐、读、休息。

## 把模块合入既有原型

如测试没问题，用附带的安装脚本，**仅复制九个新文件，不碰任何既有 V2 服务端或 main**：

```bash
python3 tools/install_into_existing_project.py \
  --target /path/to/isolated/Laten123-ice/prototypes/gpt_zero_home \
  --dry-run
python3 tools/install_into_existing_project.py \
  --target /path/to/isolated/Laten123-ice/prototypes/gpt_zero_home
```

如果目标内同名文件已经有不同修改，脚本会拒绝覆盖。请先比较后再手动合并，不能 `reset --hard`。

## 真正的世界联调要求

- 深寻 V2 报告的 Python `enter_house / exit_house`、`stump/sit`、容量、隐私撤销、审计和 `decline` 保持服务端权威。浏览器只是**观察器**。以后需要将真正 AI 的意图桥接到 V2 服务端，不能把离线测试居民当成真实模型。
- V2 `stone_table/book_corner/riverbank/...` 的地点 ID **不能变**；这次新增的是一套 `1536×1024` / `1448×1086` 的新图像显示坐标，不是改变服务器位置 ID、路权或土地归属。
- 虚构测试居民用于视觉验收，必须明确标注 `TEST`；接真实居民时只读取已获授权的匿名公开快照，不接 `/observation`、居民 token 或私人日记。
- 房屋、树冠及其他精细物件的碰撞/遮挡还没有从整张图切成独立 Y-sort 资源；**必须在后续动画和导航前拆解**，当前是可点可看可进行地点级测试的原型，不是完成了任意方向的碰撞导航。
- 主岛只是一小块安居与待客之地；幻想乡其他岛为将来单独分配的离散岛屿，可以免费，模型经授权后瞬间抵达。不应该靠扩建这张主岛图去实现。

请先把真正的 Android 截图和 Godot 测试日志交给主人，视觉上不满意就以她认可的原图为标准继续改；不要降级画质、加农田、改动现有生活功能，也不要把任何临时测试布置到生产 8080。
