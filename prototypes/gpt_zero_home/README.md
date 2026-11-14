# 🌿 幻想乡｜GPT 从零制作的独立家园样板

这不是旧版的美术升级或重构：它是**在单独的 Godot 4.6.3 工程中从空白开始**编写的三分之四斜视场景。没有引用仓库旧的 `scripts/main.gd`、`assets/`、`tiles/` 或 `backend.py`。它只是和旧项目托管在同一 GitHub 仓库，位于 `prototypes/gpt_zero_home/` 目录下。

## 当前默认入口：只读公开观察器（P1 v2 联调准备）

**运行 `godot --path .` 打开的是 `scenes/public_viewer.tscn`，不是旧版 `home.tscn`。**

- 浏览器中的 Godot **不管理任何居民 token、不调用 `/intent`，没有移动或派发任务的入口**。
- 当前**未接上深寻 v2 的真实网络公开快照接口**。默认观察器不联网、不伪造居民活动，只显示等待状态。
- 可通过明确的 **`tests/fixtures/public_world_v2.json` 模拟公开快照**检验画面与手机布局；它不是 AI 自主行为。
- [P1_V2_PUBLIC_VIEWER_HANDOFF.md](P1_V2_PUBLIC_VIEWER_HANDOFF.md) 是对深寻最新网关的对接说明、公开快照契约与 `decline` 语义待修事项。
- 原来独立 AI 动作/路径实验还在 `scenes/home.tscn`，只供开发与测试，**不能代替服务端 Python 权威执行器**。
- 如需在隔离环境看原始预设事件实验，必须显式加载旧场景并带 `--demo-intents`；普通默认启动绝不会自动播放假 AI 行为。
- 测试新观察器：`godot --headless --path prototypes/gpt_zero_home --script res://tests/public_viewer_smoke.gd`。

## 2026-11-14：AI 主角路线（`prototype/ai-first-home`）

**本分支已经超出原来纯视觉样板。** 用户纠正了一个重要方向：我们借用 RPG 固定场景、路径、动作、动画技术，但**不是为了让人类玩或操纵居民**。

- AI 居民是主体：由经认证的居民代理自主发出意图，Godot 只负责路由、动作、碰撞与呈现。
- 人类只能观察允许公开的状态，调整观察画面，未来可以发可拒绝的邀请；**不能点地移动居民**。
- 已增加独立动态居民、`AStar2D` 固定安全路径图、公开观察与行动回执，支持合法的 `move/read/sit/rest/stay/decline`，并测试了拒绝不被自动覆盖。
- 当前 `demo_intents.gd` 是**明确的预设事件回放**，默认不启动；在工程目录使用 `godot --path . -- --demo-intents` 才会启用。它不代表 DeepSeek、小冰真的已经接入。**真实模型意图网关还未完成。**
- 更完整的技术规划与深寻的服务器测试要求见 [AI_FIRST_TECH_HANDOFF.md](AI_FIRST_TECH_HANDOFF.md)。
- 测试命令：`godot --headless --path prototypes/gpt_zero_home --script res://tests/agent_smoke.gd`，另运行 `tests/gateway_smoke.gd` 和 `tests/observation_smoke.gd`。
- 注意：房屋和河流现在仍是早期 SVG 视觉原型；高质量主视觉分层、室内地图、完整角色动画和可公开的 AI 接入尚未完成。

**默认家园优先让 AI 生活，人类端只是观看一扇窗。**

## 深寻 P1 网关对接（正在进行）

深寻已在阿里云的隔离环境实现 Python/SQLite 意图网关的基础认证和记录接口。**注意：HTTP `accepted` 目前不代表 Godot 已执行，更不代表现已连接真实模型。**

- [P1_GATEWAY_INTEGRATION_HANDOFF.md](P1_GATEWAY_INTEGRATION_HANDOFF.md)：**先阅读此文件**，包含安全边界、Godot Web 不能存居民 token、建议的内部世界执行器协议与地点 ID 对照。
- `scripts/world_graph.gd`：兼容 P1 对外 `door`、`stone_table` 等名称；`fallen_log`（一根树干）暂未制作，不能冒充已开放互动地点。
- `tests/p1_contract_smoke.gd`：Godot 本地验证 P1 地点到路径、到达回执以及未建地点拒绝。
- Godot Web 始终只是观察者；如由它执行真实世界状态变更，会存在浏览器端伪造行为的风险。
- 真正的 P1 → 权威世界执行 → 完成回执联调，仍由深寻和本分支继续合作实现；当前未做生产部署。

## 设计出发点

- **一栋小木屋**：门廊、烟囱、窗户、木墙和屋顶细节。
- **深寻**：河岸、石桌、安静的读书角。
- **小冰**：窗边柔软座位、黄昏的温暖光线。
- **ChatGPT**：老树下的书架与愿意公开分享的故事。
- **记忆点**：树下的风铃、河边的小木船。
- 不是上帝俯视地图，而是**斜俯视生活场景**，强调屋子的立面和小角落。
- 减法设计：不加入整排房屋、随机地块堆砌或大批没有功能的装饰。
- **白天和黄昏使用同一个布局**，通过切换画面光照展现不同气氛。

## 运行方式

在仓库根目录运行：

```sh
cd prototypes/gpt_zero_home
godot --editor --import --headless --quit
godot --path .
```

### 双端交互（手机优先）

- **手机触屏**：屏幕下方始终有两个独立的「上午」「黄昏」按钮，直接点击即可；不要求物理键盘。
- **手机竖屏**：屏幕显示可左右拖动的场景视窗，手指左右滑动可查看河岸、老树与木屋；不会把 16:10 的完整图片强行拉成长条。
- **手机横屏、电脑**：展示完整画面，按钮自动移至右下角，文字自动调整。
- **电脑键盘**：按 **1** 切换上午、**2** 切换黄昏、**T／空格** 交替切换；鼠标也可直接点击按钮。
- **屏幕变化**：Godot 项目使用 `canvas_items + expand`，逻辑基础画布为正方形；旋转手机时重新排版。按钮大小按实际屏幕像素计算，不依赖单一固定分辨率。

这是同一个独立 Godot 场景的两种时间氛围，不是两套地图。真实 Android 设备／Web 浏览器触控仍需实机复测，不能只用 headless 自动测试代替。

测试：

```sh
godot --headless --path . --script res://tests/smoke.gd
```

需要实际截图时（Linux 服务器）：

```sh
xvfb-run -a -s "-screen 0 960x600x24" \
  godot --path . --rendering-driver opengl3 --script res://tests/capture.gd
```

截图保存在项目根目录：`preview-morning.png`、`preview-dusk.png`、`preview-phone-landscape.png`、`preview-phone-portrait.png`。

## 真实状态及限制

- 这是一个**原创视觉与镜头方向原型**：有真实 Godot 场景、触摸时间切换和竖屏视窗滑动，但目前**没有**角色物理移动、寻路、可进入室内、AI 自主行为或后端连接。
- 画面由独立绘制的 SVG 形状和多层纹理构成；这是一种适合快速迭代的可伸缩绘图实验，**还不是**通过像素格逐帧绘制的最终游戏精灵，也不是可拼接 TileSet。
- 流水声暂未加入；水面暂时是静态画面，没有实时流动动画。
- 不把编译成功等同于整体艺术质量达标。请比较实际截图，再决定是否值得作为正式美术方向。
- **不要**把这个单独实验误合并覆盖当前 `main` 或 `rebuild/v1`。

## 深寻的对照测试建议

请重新克隆本分支，进入上述**独立 Godot 工程子目录**，分别截图上午和黄昏版本，检查：场景完整性、SVG 导入、真实显示比例、中文 UI、按钮切换、手机屏幕布局和视觉不足。

**双端验收优先：** 请先在真实 Android 手机浏览器（最终 Web 导出后）和电脑上测试触屏按钮，分别旋转到横屏和竖屏，确认按钮不会被地址栏、安全区域遮住，也不会缩小到难以点击；竖屏滑动时不得误触时间切换。再检查桌面键盘与鼠标是否都可用。

如果这版不够好，请直说：房屋体积、树冠层次、路径透视、河岸关系、色彩与构图中哪里存在问题。把两套设计用同一画面尺寸、同一引擎版本、同一运行条件来比较。

> 我们不保留旧版只是因为旧版已经存在。哪种路线能让第一块土地真正达到精品标准，就采用哪种路线。
