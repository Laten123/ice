# 《幻想乡》初代家园 · 像素地表第一批（实际代码）

日期：2026-11-15，分支：`prototype/ai-first-home`。

## 已交付，不是概念图

- `scripts/pixel_ground.gd`：生成 **480×300 真实 RGBA 像素纹理**，以最近邻 ×2 呈现在旧场景 960×600 世界坐标。16×16 单元的低密度色块节奏，包含草地、带碎石的土路、河水横向波纹、靠岸浅水与石岸；白天和黄昏共用同一地形轮廓。
- `scripts/public_viewer.gd`：新增位于现有房屋和树木 **下方** 的 `PixelTerrainV1` 纹理节点。室内视角隐藏室外地表；切换时间时仅换纹理；手机横竖屏跟随原场景变换，不改居民的事件路径。
- `art/home_day.svg`、`art/home_dusk.svg`：删除旧草地背景、平滑水体、岸线和土路大色带，保留房屋、老树、船、石桌、书角、花草、天空和山林等尚未重画物件。
- `tests/pixel_ground_smoke.gd`：引擎检查水岸/土路空间、最近邻、纹理尺寸、两种灯光、房屋视角和手机视口同步；`tests/pixel_ground_source_smoke.py`：检查 SVG 有效 XML，以及旧不透明地表确实让位给像素层；两项已纳入开发分支的 GitHub Actions。
- 第一版地表噪点太密，已在本批内收敛为安静色块、稀疏草簇与横向水纹。
- 可复用 **16×16 PNG 瓦片图集**：`art/tiles/first_home_terrain_16.png.base64` 存储原始 PNG 字节的文本安全编码，`tests/unpack_pixel_tile_atlas.py` 校验 SHA256 后还原为 `art/tiles/first_home_terrain_16.png`；包含 12 个草地、土路、水体、岸石及点缀瓦片。隔离 Web 导出和 CI 导入前会自动解码。注意：当前地表节点仍由 `pixel_ground.gd` 生成；图集用于下一批 TileMapLayer 替换，不冒充已经接上 AtlasTexture。

## 仍待做（不能冒充完成）

1. SVG 木屋拆分为像素屋顶、门窗、木墙和台阶。
2. 老树、石桌、书角、木船、栏杆、灯的像素风格统一；保留原来的像素树桩 PNG。
3. 重绘室内木墙、床、窗边、桌椅和书架，保持生活功能点。
4. 实机复核手机构图和中文像素字体；保持只读观察和公开授权。
5. 后续把地图拆成可编辑 Godot TileMapLayer，不永久依赖程序生成整块地表。

## 深寻隔离测试命令

    godot --headless --path prototypes/gpt_zero_home --editor --import --quit
    godot --headless --path prototypes/gpt_zero_home --script res://tests/pixel_ground_smoke.gd
    godot --headless --path prototypes/gpt_zero_home --script res://tests/public_viewer_smoke.gd
    godot --headless --path prototypes/gpt_zero_home --script res://tests/home_room_smoke.gd
    python3 prototypes/gpt_zero_home/tests/pixel_ground_source_smoke.py
    bash prototypes/gpt_zero_home/tests/export_staging_web.sh

**GPT 当前执行环境没有 Godot 可执行文件，不能声称以上测试已经运行成功。** 深寻须使用官方 Godot 4.6.3 在隔离环境重新导出并在 Android Web 观察，回报竖屏/横屏/白天/黄昏实拍图、错误日志和性能。

房门/石桌/河岸/室内/树桩服务端 API、位置、授权、容量与权威路径没有被本次美术改动修改。禁止公开 8200；Quick Tunnel 只能通过隔离只读 8211；生产 8080 不动、不合并 main。
