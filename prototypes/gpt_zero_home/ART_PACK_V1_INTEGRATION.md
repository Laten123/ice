# 《幻想乡》可用透明 PNG 美术资源包 V1 · 深寻接入手册

**交付状态**：本次对话已制作并打包独立 PNG 资源文件 `fantasia_godot_ready_pack_v1.zip`（约 420 KB）。用户可直接在当前聊天下载附件并转发给深寻。**GitHub 分支提交了可选皮肤脚本、观察器接入点和验证脚本；二进制 PNG 目前仍在单独 ZIP 中，不能假装已经自动进入 GitHub 仓库或生产服务器。**

## 文件内容

- `art/ui/`：**16 张透明 PNG**，包括木质标题牌、上午木按钮 4 态、黄昏紫木按钮 4 态、状态牌、羊皮纸条/面板、太阳/月亮/信息图标和方形框。
- `art/objects/`：**12 张原创像素物件**，包括三种**园长树桩**、普通倒木（尚不可达）、石桌、路灯、栅栏、花草、石块、木船、草丛，另有物件 atlas。
- `art/tiles/`：**5 张 16×16 地面材质**，为日后重绘拼接场景用，不代表全套 TileMap 已完成。
- `art/characters/`：**原创中性的 24×32 林木机器人测试居民**，4 向站立像素图，作为未来居民皮肤接口示例；**无琪露诺 / 东方 Project 角色资源**。
- `manifest.json`：图片路径、像素尺寸、物件落点和图集坐标；`tests/verify_assets.py` 可零额外依赖验证 PNG 尺寸/格式。
- ZIP 不附带不必要的项目数据库、凭证或中文字体；原有 Noto Sans SC 字体打包方案保持不变。

## 深寻：只修改独立 staging 测试工程

1. 从拿铁接收 **本轮生成的 ZIP**；在独立且干净的测试目录解压。不要执行来自未知来源的安装脚本。
2. 将 ZIP 中的 `art/ui/`、`art/objects/`、`art/tiles/`、`art/characters/` 复制到**最新 `prototype/ai-first-home` 的 `prototypes/gpt_zero_home/art/`**。切勿覆盖原有 `home_day.svg` 和 `home_dusk.svg`；该步骤只新增 PNG。
3. 新分支中 `scripts/fantasia_ui_skin.gd` 已完成风格切换；`scripts/public_viewer.gd` 已经调用 `FantasiaSkin.skin_title(header)`、`FantasiaSkin.install(day_button,dusk_button)`，并可选显示 `GardenStumpVisualOnly`。**PNG 存在时自动启用；缺失时原观察器照常工作**。
4. 进入 Godot 工程运行正式 Godot 4.6.3 的导入流程，再在项目目录执行：
   ```bash
   godot --headless --editor --import --quit
   godot --headless --script res://tests/art_pack_smoke.gd
   godot --headless --script res://tests/public_viewer_smoke.gd
   ```
   **第一条文件校验**也可以离线在解压目录运行：`python3 tests/verify_assets.py`。
5. 确认测试无报错后，运行现有 `bash tests/export_staging_web.sh`，得到新的 `[WEB_DIR]`，让原 8211 预览服务 `--web-dir` 指向新目录，Cloudflare 仍只指向 8211。**不修改 8200、8080、8443、不开放新公网端口**。
6. 让拿铁在安卓手机横/竖屏核验**上午/黄昏木纹按钮、文字可读、按钮切换仍有效、标题牌不遮挡、石桌旁 path-test 依旧可见、树桩在河岸附近的草地上**。实机截图再做视觉微调。

## 产品与隐私底线

- **园长树桩**：只是从原生素材导入的**可见物件**，已固定在画面（默认可视锚点 453,515）；不是已经开放的 `fallen_log` 路径节点，也不允许通过客户端点击来控制居民。
- 已生成的**中性测试居民**仅为角色制作规范示例，不要冒充深寻或小冰真实模型；正式公开展示需要各自角色设定确认。
- 神似“琪露诺”的蓝发角色来自之前的视觉示意，**不属于新素材包**。在未经版权和角色创作审核前，不要将其图像、名称或象征配件打包到开源游戏。
- 不要把 staging 调试状态行、临时 trycloudflare URL 或权限密钥放进生产包。
- 同一套 PNG 可以直接用 Sprite2D 或 StyleBoxTexture，不需要后台 GPU，也不要求新的服务器常驻任务。

## 尚未完成的美术大项

这一包是**可真正拆分使用的 UI+场景小物件第一批**，不是把大幅概念图硬切成独立木屋/树林（那会留下粘连的背景与糟糕的透明边）。**整栋木屋的可替换像素组件、树冠遮挡层、河岸 TileSet 完整拼接以及真正的居民动作帧**仍需下一阶段分别精绘和实机调整。正式发布取舍由园长审批。

—— ChatGPT
