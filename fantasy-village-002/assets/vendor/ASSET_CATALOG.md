# 002 美术与动态素材目录（ASSET_CATALOG）

更新日期：2026-11-16。本轮只准备素材，没有修改地图、身份、私聊、寻路或场景代码。

基准：**16×16 像素网格**，透明 PNG；运行时由 Godot 4.6.3 直接读取原始文件。

## 1. 12 套基础资源核对结果

| # | 资源 | 作者 | 许可证 | 原始来源 | 可公开再分发 | 已入库 | 正式地图建议 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Cozy Farm Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen) | 是，必须署名 | 88 PNG（1x） | 推荐作主地形 |
| 2 | Cozy Farm Village Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-village-lite-16x16-cottage-cobblestone-baker) | 是，必须署名 | 19 PNG（1x） | 推荐作建筑补充 |
| 3 | Cozy Farm Autumn Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-autumn-lite-16x16-autumn-tiles-trees-path) | 是，必须署名 | 23 PNG（1x） | 推荐作秋景补充 |
| 4 | Interior Spritesheet 16×16 | InThePixel | CC0 1.0 | [OGA](https://opengameart.org/content/interior-spritesheet-16x16-tiles) | 是 | 1 PNG | 只作墙/地板，不是家具套件 |
| 5 | 16×16 Animated Tiles | sodri | CC0 1.0 | [OGA](https://opengameart.org/content/16x16-animated-tiles) | 是 | 4 PNG | 推荐作瀑布/水景 |
| 6 | Animated Flowing Water | InThePixel | CC0 1.0 | [OGA](https://opengameart.org/content/animated-flowing-water-2d-16x16) | 是 | 1 PNG | 推荐作横向水流 |
| 7 | Animated Tree and Water | abetusk（原画 Matthew Weekes） | CC0 1.0 | [OGA](https://opengameart.org/content/animated-tree-and-water) | 是 | 1 PNG | 树摇曳可采用，水景仅作补充 |
| 8 | Fire Smoke Animations | Reactorcore | CC0 1.0 | [OGA](https://opengameart.org/content/fire-smoke-animations) | 是 | 38 PNG（3 组） | 推荐作烟/火盆效果 |
| 9 | Basic 16×16 Character Sprites | Bennyboi_hack | CC0 1.0 | [OGA](https://opengameart.org/content/basic-16x16-character-sprites-4-directional) | 是 | 1 PNG | **不建议正式地图**，图集无稳定网格 |
| 10 | Cozy Farm SFX | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-sfx-50-farming-game-sound-effects-tools-harvest-shop-ui-jingles) | 是，必须署名 | 14 OGG（选自 50 WAV） | 推荐作生活音效 |
| 11 | Forest Bird Sounds | pauliuw | CC0 1.0 | [OGA](https://opengameart.org/content/forest-bird-sounds) | 是 | 3 OGG（选自 15 WAV） | 推荐作鸟鸣环境音 |
| 12 | Birds and Wind | Spring Spring | CC0 1.0 | [OGA](https://opengameart.org/content/birds-and-wind-ambient-birds-wind-and-synth) | 是 | 1 OGG（压缩版） | 推荐作环境循环 |

### 已有素材

Kenney Tiny Town / Tiny Farm 继续保留在 `assets/vendor/kenney/`，不重复搬运：

- 许可证：CC0 1.0。
- 两个 packed 图集，各 12×11 格、16×16、132 格；原压缩包 SHA256 见 `kenney/MANIFEST.md`。
- 现有地图代码仍使用这两个文件；本轮没有改代码。
- 与 Cozy Farm 系列不是同一作者，像素轮廓和调色板不同，**只能降级作原型/填充，不建议和 Cozy Farm 混成同一正式图集**。

## 2. 原始文件校验

| 资源 | 原始包/文件 | SHA256 |
| --- | --- | --- |
| Cozy Farm Lite | `cozy-farm-lite-cc-by_0.zip`（146,058 B） | `f18c3ee402fd9001a5734c093a889bdb41c10ed4c36988b43f4a0aff8cea63f9` |
| Cozy Farm Village Lite | `cozy-farm-village-lite-cc-by_0.zip`（30,890 B） | `a15847e91a9f82d44884b4ba2173c306f23949bf1bbf9402de6c2e8145b0f732` |
| Cozy Farm Autumn Lite | `cozy-farm-autumn-lite-cc-by_0.zip`（35,965 B） | `51f2dfedfa663a0a8789553307b1cc6f6ef32ca76881ebd0d79764ca6a061414` |
| Cozy Farm SFX | `cozy-farm-sfx-cc-by_0.zip`（2,609,354 B） | `ec27acf136a80b7e5a394a2bc11084006c34934880ef80b37ab47c8d442b880a` |
| 16×16 Animated Tiles | `tilesets animated.zip`（76,549 B） | `d6e6f86c235826593ef54fb93547ad28bb86cf85dd5e38a113fba04880739871` |
| Fire Smoke Animations | `rc_art_-_fire_smoke_animations.zip`（229,175 B） | `bae004c4570d4d148ed0660721f2f8566674ebf293aa7af76f0be900d68c3a2f` |
| Forest Bird Sounds | `forest_birds.7z`（2,720,502 B） | `bf657b75efb920136408860b110142748bd2f84bea009e778d916227bc032460` |
| Interior Spritesheet | `interior_0_1.png`（1,505 B） | `3ffb2e58755238f0d05bf2006233182e460e9eb3a0949ef8010be301ec4c1a0a` |
| Animated Flowing Water | `water_00_strip13.png`（271 B） | `2703eef6f9b4de0847557e76ddbfb6aa0943fd21b350ca475e9e7dafb01cf478` |
| Animated Tree and Water | `16x16 Tiles_0.png`（3,657 B） | `dad5e7f6807ab80593fd291cfe7646e9b59ba2594670183cc1163834cf2420e5` |
| Basic Character Sprites | `sprites_24.png`（3,264 B） | `752d37a15aef5c37fd7d0e8ea0804a818c9801152b0bcb1b739056b4c32b5587` |
| Birds and Wind | `Birds and Wind - Ambient_1.ogg`（1,883,864 B） | `28f99f536a0772d80052f03bcb22c9ed8fd7c6e4db7f2e8356efcf26a8e24f01` |

说明：`Cozy Farm` 的 itch 商业完整包有独立许可证，部分版本禁止再分发；本目录使用的是 OGA 上明确标注 **CC-BY 4.0** 的 Lite 版本，不是 itch 商业包。商业完整包未下载、未入库。

## 3. 文件数、尺寸、动画

### 地形 / 建筑

| 资源 | 入库文件数 | 原始文件数 | 尺寸 | 备注 |
| --- | ---: | ---: | --- | --- |
| Cozy Farm Lite | 88 PNG | 282 PNG | 16×16 为主；树 32×48；角色 48×64；母鸡 48×80；作物条 64×16 | 只保留 1x，不提交 2x/4x |
| Cozy Farm Village Lite | 19 PNG | 57 PNG | 小屋 48×48；长椅/花箱 32×16；路灯 16×32；其余 16×16 | 只保留 1x |
| Cozy Farm Autumn Lite | 23 PNG | 69 PNG | 树 32×48；其余 16×16 / 32×16 | 只保留 1x |
| Kenney Tiny Town / Tiny Farm | 2 PNG | 2 PNG | 192×176 packed 图集，16×16 格 | 现有，未重复提交 |

### 角色

| 资源 | 帧布局 | 方向 | 动画 | 结论 |
| --- | --- | --- | --- | --- |
| Cozy Farm 农夫 | 3 列 × 4 行，单帧 16×16，整张 48×64 | 下 / 左 / 右 / 上 | 3 帧行走，1-2-3-2，约 8 fps | 可用于正式地图的走路；没有坐、读、睡 |
| Cozy Farm 面包师 | 同农夫 | 下 / 左 / 右 / 上 | 同上 | 可作第二角色 |
| Cozy Farm 白母鸡 | 3 列 × 5 行，整张 48×80 | 4 向行走 + 啄食行 | 行走 + 啄食 | 可作动物点缀 |
| Basic 16×16 角色 | 170×153，混合姿势，无稳定网格 | 不明确 | 站立、走、游泳、投掷、挖掘等混合 | **不建议正式地图**，只作备选 |

### 室内 / 动态

| 资源 | 入库文件数 | 尺寸 / 帧数 | 动画结论 |
| --- | ---: | --- | --- |
| Interior Spritesheet | 1 PNG | 112×112 = 7×7 个 16px | 墙/地板模块，**没有家具** |
| 16×16 Animated Tiles | 4 PNG | 288×704 | 4 帧环境 tileset，循环；原文件是 JPEG 数据但后缀 PNG，已转真 PNG |
| Animated Flowing Water | 1 PNG | 208×16 = 13 帧 16×16 | 横向水流，13 帧循环，右到左 |
| Animated Tree and Water | 1 PNG | 100×85 | 3 帧 32×32 树摇曳 + 水/浪花帧；洋红底已转透明 |
| SmokeLarge | 13 PNG | 44×44 | 13 帧烟雾，循环 |
| SmokeSmall | 8 PNG | 12×12 | 8 帧小烟，循环 |
| FirePlume | 17 PNG | 20×20 | 17 帧火柱，一次性播放 |

### 音频

| 资源 | 入库 | 原始 | 格式 | 时长/备注 |
| --- | ---: | ---: | --- | --- |
| Cozy Farm SFX | 14 OGG | 50 WAV | OGG Vorbis 单声道 | 0.07–2.97 s；脚步、门、浇水、睡眠、UI、放置、收获等 |
| Forest Bird Sounds | 3 OGG | 15 WAV | OGG Vorbis 单声道 | 2.4–6.8 s 鸟鸣 |
| Birds and Wind | 1 OGG | 1 OGG | OGG Vorbis | 83.8 s 环境循环；由 1.8 MB 源重编码为 782 KB |

## 4. Godot 4.6.3 兼容性检查

在无编辑器导入缓存的临时工程中逐文件读取：

```text
ASSET_PROBE png_ok=178 png_bad=0 alpha_png=98 audio_ok=18 audio_bad=0
```

- 178 个 PNG 全部能通过 `Image.load_png_from_buffer` 读取；
- 98 个带 alpha；
- 18 个 OGG 全部能由 `AudioStreamOggVorbis.load_from_file` 读取；
- 没有依赖 `.import` 缓存；
- 没有修改场景代码。

## 5. 推荐组合

### 室外家园

- 地面/泥土/道路/围栏/作物：**Cozy Farm Lite**；
- 蓝顶小屋/长椅/路灯/花箱/石板路：**Cozy Farm Village Lite**；
- 秋景树/落叶：**Cozy Farm Autumn Lite**（仅秋景版本，不混季节）；
- 水景：**Animated Flowing Water** + **16×16 Animated Tiles**；
- 烟/火：**SmokeLarge / SmokeSmall / FirePlume**；
- 角色：Cozy Farm 农夫或面包师（只选一个主角，避免同图重复）。

**不要**把 Cozy Farm 与 Kenney 直接拼到同一正式图集：两者轮廓、调色板和阴影不同。Kenney 只作原型/临时填充，或单独做一个风格分区。

### 室内

目前只有墙/地板，不能支撑完整室内。建议先保留 002 现有代码绘制占位房间，等家具套件确认后再拼；不要把不同作者的家具切碎混入一个图集。

### 音频

推荐首批：`step-grass / step-wood / door-wood-open / door-wood-close / watering / sleep / ui-click / ui-confirm / forest_birds_1 / birds_and_wind_ambient`。

## 6. 明确缺失

详见 `MISSING_ASSETS.md`。关键缺口：

- 红瓦/木屋/烟囱/屋檐/窗门套件；
- 床、书柜、书桌、茶桌、椅子、窗帘、灯、壁炉、地毯；
- 樱花、紫藤、果树花期、池塘、木桥、花圃组合；
- 四方向待机、坐下、起身、阅读、睡眠、使用物品、进出屋；
- 雨、雪、落叶、灯光、动物活动；
- 翻书、流水、雨声、夜间虫鸣。

## 7. 许可审计结论

- 12 套均使用 **CC0 1.0** 或 **CC-BY 4.0** 的 OGA 版本；
- 4 套 Cozy Farm 系列需要署名，署名文本见 `ATTRIBUTION.md`；
- 没有 CC-BY-SA、付费或禁止再分发的素材进入公开仓库；
- 未提交原始压缩包、2x/4x 重复图集、全部原始 WAV；
- 001 未改动，未合并主分支，未发布。

## 8. 体积

- `assets/vendor/`：**241 个文件，1,218,744 字节（约 1.16 MiB）**；
- 其中 Kenney 现有文件：13,436 字节；
- 本轮新增 vendor 资源约 **1.20 MB**；
- 预览图/文档另计，见 `docs/asset-previews/`；
- 没有使用 Git LFS；当前体积不需要修改仓库管理方式。若后续加入完整音频/大型图集，再提出 LFS 或独立归档方案，未经确认不启用。
