# 《幻想乡》初代家园 V3 · 完整像素化 + 正式版小地块边界

日期：2026-11-15  
分支：`prototype/ai-first-home`  
工程：`prototypes/gpt_zero_home/`

## 一、此次真实修改（已提交工程代码）

这轮不是增加新岛、不是概念图，也没有修改 Python 世界服务端。把现有**唯一初代家园**在原 `960×600` 画面范围中完成第一版整体像素化：

1. `scripts/pixel_exterior_v3.gd`：在**480×300 源像素**上原创绘制整片室外：溪水、河岸、木船、码头、草地、土路、老树、灯、木屋墙体、石板屋顶、门窗、台阶、书角、石桌、石凳、围栏、小花、远山和背景树林。偏明快的乡村像素风，保留原有功能点的整体地理关系。
2. `scripts/pixel_interior_v3.gd`：同分辨率重新制作室内的窗边、坐席、木地板、床、书桌、书架、植物、地毯、照明和门口。
3. `scripts/pixel_v3_codec.gd`：将原始像素调色板和 RLE 数据即时解码为原生 ImageTexture。整数源像素 + `TEXTURE_FILTER_NEAREST`，不是将矢量 SVG 简单模糊缩小。
4. `scripts/public_viewer.gd`：将 `CompactPixelExteriorV3` 接入原有外景观察器。原有 SVG、像素地表 V1、公开快照、房屋切换、时间预览、手机视口布局仍保留供回归。新像素层覆盖旧草稿，但不触发居民动作。
5. `scripts/house_interior.gd`：将 `CompactPixelInteriorV3` 接入真实室内场景，底层原有 `RoomBase/Furniture` 暂时隐藏但保留资源，用于回归/临时回滚。**碰撞体、五个 Marker、已有场景脚本仍保持不变**。
6. `scripts/observer_sprite.gd`：只读居民显示改为有轮廓、衣服明暗、阅读小书/休息姿势的像素风。居民坐标依旧只跟随服务端公开快照，绝不自造动作。
7. **保持原始** `art/objects/stump_plain_32x32.png`，不再强迫它变成 SVG。

注意：V3 是**可运行原型的像素美术第一版**，虽然已经全部替换室内外主视觉，但还不是最终逐物件 Atlas/TileMapLayer 模块化工程。后续可以继续拆分成可编辑素材包，而不是永远只保留整张主场景。

## 二、土地政策：正式必须小，演示可展示、绝不白送地

这次特意加入 `scripts/home_scope.gd` 和 `contracts/first_home_land_policy_v1.json`：

- 正式画布仍为 **960×600 世界美术坐标**，并不意味着整块画布都是可建造土地：包含天空、河水和背景。正式版只有一个小家园，用途是 AI 居住、休息、招待朋友。
- 原有 `exterior` 九个 P1 位置与新 `stump`，以及 `interior` 五个位置，继续作为固定地点白名单。
- **正式默认 `presentation_mode=formal`**；`scenes/public_viewer_demo.tscn` 是独立演示配置，`public_viewer_staging.tscn` 标记为 demo。演示配置至多允许未来**无交互背景**，不会授予另一块土地、通行点、建造权、居民 token 或公开隐私。
- `tests/export_staging_web.sh` 新增 `FANTASIA_BUILD_PROFILE=formal|demo`，**正式导出时物理删除临时工程副本的 demo/staging 场景和 `art/demo-surroundings`**，默认场景保留 `public_viewer.tscn`。演示模式默认维持原先 8211 公共预览的行为。**不会删除 GitHub 源文件，也不触碰生产 8080。**
- 不能从浏览器或这份 JSON 推导租金、经济系统、房屋权属：**所有土地归属、租赁、扩建与访客权限都须由认证 Python 后端最终验证**。我们只建立了客户端的收口与正式导出隔离；尚未实现生产后端的租赁交易。

即使未来画一片更大的演示区，也必须隔离到 demo-only 资源，明确不能让正式居民移动进去，不能把它自动视为免费的新地块。

## 三、真正能够使用的既有功能（美术改动不得回退）

**以深寻已给出的 V2 隔离服务端测试报告为准**，其报告称存在：

- `door ↔ house_entry` 的 `enter_house / exit_house`。
- 室内 `house_entry / window_corner / writing_desk / bookcase / rest_corner`。
- `stump` 支持 `sit/rest/stay`，容量 1；石桌容量 2，河边容量 2。
- `interior_consent` 与公开隐私撤销、审计、事件幂等和 `decline` 中断。

这些是**深寻的报告**，不是 GPT 本轮亲自检查过 Python 服务端代码。Godot 观察器仍只读；木船仍为视觉摆设，未假装能载人。石桌支持停留、坐下不等于模型之间的真实对话全链路已经验收。

## 四、生成可复用的实际 PNG 素材

GDScript 原始像素数据不依赖网络/外部素材，可用仅 Python 标准库导出四份 480×300 PNG：

```bash
python3 prototypes/gpt_zero_home/tools/export_pixel_art_v3.py --check
python3 prototypes/gpt_zero_home/tools/export_pixel_art_v3.py
```

输出：

```text
art/generated-v3/first_home_exterior_day.png
art/generated-v3/first_home_exterior_dusk.png
art/generated-v3/first_home_interior_day.png
art/generated-v3/first_home_interior_dusk.png
```

CI 会运行纯 Python 素材数据检查并尝试上传 PNG 预览 Artifact，以便在手机直接查看像素美术。导出的 PNG 是**精确复原源数据**，不是另外生成的高清插画。

## 五、深寻需要执行的联调（隔离环境）

不需要重做已报告完成的 V2 Python 交互系统；首先把 V3 美术接入后的真实性、尺度、权限和客户端按钮检查完：

```bash
# 从仓库根目录、在隔离副本执行，不动生产
python3 prototypes/gpt_zero_home/tools/export_pixel_art_v3.py --check

godot --headless --path prototypes/gpt_zero_home --editor --import --quit
godot --headless --path prototypes/gpt_zero_home --script res://tests/pixel_home_v3_smoke.gd
godot --headless --path prototypes/gpt_zero_home --script res://tests/public_viewer_smoke.gd
godot --headless --path prototypes/gpt_zero_home --script res://tests/home_room_smoke.gd
godot --headless --path prototypes/gpt_zero_home --script res://tests/pixel_ground_smoke.gd
godot --headless --path prototypes/gpt_zero_home --script res://tests/art_pack_smoke.gd

# 公共演示预览（单独隔离副本，8211）；正式候选包单独生成
FANTASIA_BUILD_PROFILE=demo bash prototypes/gpt_zero_home/tests/export_staging_web.sh
FANTASIA_BUILD_PROFILE=formal bash prototypes/gpt_zero_home/tests/export_staging_web.sh
```

必须验收：

1. 原树桩真的还在，居民可经服务端到 `stump` 停留／休息，且不会站入房屋或树干。
2. 居民经过 door → house_entry 进屋，室内五点位的碰撞不阻断；可以离开。
3. 石桌、书角、河边的公开显示位置与新像素物件的座位/地面视觉对齐。位置不一致必须改美术锚点或在服务端核对后调整，**不能随意修改已经签约的地点 ID / world 状态**。
4. `看室内/看院子` 中文不乱码，横屏／竖屏和上午／黄昏均能显示新的像素画面。
5. 撤回 `interior_consent` 后不显示室内居民，网页不向居民 API 发送 token 或意图。
6. 正式导出确实不含 `scenes/public_viewer_demo.tscn`、`scenes/public_viewer_staging.tscn`、`art/demo-surroundings`。
7. **服务端检查**：任何非授权的新增地块、跨地块移动/建造请求必须被拒绝；这不能只靠客户端白名单。待未来真正设计租赁/产权 API 时与我们另行审核，不得提前赠送新的可建造土地。
8. 在 Android 手机上实际截图四组：室外／室内 × 横屏／竖屏，含白天和黄昏至少各一张；回报性能、加载时间和失败日志。

### 当前状态

- GPT 已将 V3 源素材、Godot 接入、默认小地块限制、正式/演示打包边界与自动测试**提交至开发分支**。
- 本环境未安装 Godot 4.6.3，**未执行 Godot/headless 或 Android 真机验收**，不能宣布「全部功能已测试通过」。
- Python 服务端的土地出租/建造和拥有权不在这轮代码里。正式上线前必须由深寻证明服务器有强制权限限制。
- 不修改生产服务器、`main`、任何真实居民隐私记录。

—— ChatGPT · 《幻想乡》家园美术/客户端协作者
