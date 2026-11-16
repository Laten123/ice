# 素材许可证证据与修改记录

本文件区分三类信息：

1. **原始许可证**：原始页面和原始压缩包内的许可证文件；
2. **项目说明**：`SOURCE.md`、`PACK_README.txt` 和本目录的整理文字；
3. **转换/派生物**：为了 Godot 读取或本项目使用而修改过的文件。

原始许可证文件随包保存在各自目录；本文件不替代原始许可证。

## 1. 原始素材核验

| 素材 | 作者 | 原始许可证 | 原始页面 | 原始包/文件 SHA256 | 入库文件 | 原始数量 | 修改 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cozy Farm Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen) | `f18c3ee402fd9001a5734c093a889bdb41c10ed4c36988b43f4a0aff8cea63f9` | 94 PNG（含 1x sheets/tileset） | 282 PNG | 只取 1x，未改像素 |
| Cozy Farm Village Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-village-lite-16x16-cottage-cobblestone-baker) | `a15847e91a9f82d44884b4ba2173c306f23949bf1bbf9402de6c2e8145b0f732` | 19 PNG | 57 PNG | 只取 1x，未改像素 |
| Cozy Farm Autumn Lite | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-autumn-lite-16x16-autumn-tiles-trees-path) | `51f2dfedfa663a0a8789553307b1cc6f6ef32ca76881ebd0d79764ca6a061414` | 23 PNG | 69 PNG | 只取 1x，未改像素 |
| Cozy Farm SFX | Bramble & Byte / roberto mellado | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-farm-sfx-50-farming-game-sound-effects-tools-harvest-shop-ui-jingles) | `ec27acf136a80b7e5a394a2bc11084006c34934880ef80b37ab47c8d442b880a` | 14 OGG | 50 WAV | 选 14 条，转 OGG 单声道 |
| Interior Spritesheet 16x16 | InThePixel | CC0 1.0 | [OGA](https://opengameart.org/content/interior-spritesheet-16x16-tiles) | `3ffb2e58755238f0d05bf2006233182e460e9eb3a0949ef8010be301ec4c1a0a` | 1 PNG | 1 PNG | 未改像素 |
| 16x16 Animated Tiles | sodri | CC0 1.0 | [OGA](https://opengameart.org/content/16x16-animated-tiles) | `d6e6f86c235826593ef54fb93547ad28bb86cf85dd5e38a113fba04880739871` | 4 PNG | 4 JPEG 数据（.png 后缀） | JPEG → 真 PNG，未改像素 |
| Animated Flowing Water | InThePixel | CC0 1.0 | [OGA](https://opengameart.org/content/animated-flowing-water-2d-16x16) | `2703eef6f9b4de0847557e76ddbfb6aa0943fd21b350ca475e9e7dafb01cf478` | 1 PNG | 1 PNG | 未改像素 |
| Animated Tree and Water | abetusk（原画 Matthew Weekes） | CC0 1.0 | [OGA](https://opengameart.org/content/animated-tree-and-water) | `dad5e7f6807ab80593fd291cfe7646e9b59ba2594670183cc1163834cf2420e5` | 1 PNG | 1 PNG（白/洋红背景） | 白 + 洋红背景转 alpha；透明像素 RGB 清零 |
| Fire Smoke Animations | Reactorcore | CC0 1.0 | [OGA](https://opengameart.org/content/fire-smoke-animations) | `bae004c4570d4d148ed0660721f2f8566674ebf293aa7af76f0be900d68c3a2f` | 38 PNG（3 组） | 147 PNG | 选 3 组，未改像素 |
| Basic 16x16 Character Sprites | Bennyboi_hack | CC0 1.0 | [OGA](https://opengameart.org/content/basic-16x16-character-sprites-4-directional) | `752d37a15aef5c37fd7d0e8ea0804a818c9801152b0bcb1b739056b4c32b5587` | 1 PNG | 1 PNG | 洋红背景转 alpha |
| Forest Bird Sounds | pauliuw | CC0 1.0 | [OGA](https://opengameart.org/content/forest-bird-sounds) | `bf657b75efb920136408860b110142748bd2f84bea009e778d916227bc032460` | 3 OGG | 15 WAV | 选 3 条，转 OGG 单声道 |
| Birds and Wind | Spring Spring | CC0 1.0 | [OGA](https://opengameart.org/content/birds-and-wind-ambient-birds-wind-and-synth) | `28f99f536a0772d80052f03bcb22c9ed8fd7c6e4db7f2e8356efcf26a8e24f01` | 1 OGG | 1 OGG | 重编码压缩 |

## 2. 补充素材

| 素材 | 作者 | 许可证 | 原始页面 / SHA256 | 入库 | 修改 / 备注 |
| --- | --- | --- | --- | --- | --- |
| Cozy Town Lite | Spaceyyy | CC-BY 4.0 | [OGA](https://opengameart.org/content/cozy-town-lite-%E2%80%94-16x16-top-down-street-tiles-caf%C3%A9-and-walking-character) / `5d24139f78278410699daa94047f6b1adba36f005a24d72daa1edf937c2eb506` | 3 PNG + 1 JSON | 只取 1x；咖啡屋 80×80、街道 tiles、player idle/walk 96×192 |
| Cottage Core Bedroom Furniture | Pixelandbeans | CC-BY 4.0 | [OGA](https://opengameart.org/content/cottage-core-bedroom-furniture-set) / `32aa48e7d7b8e74093a9b5876c08de05413c4c081c81dfe599089d6322726107` | 1 PNG | 333×64 原图；未改像素；相对 Cozy Farm 是不同作者、不同细节密度 |
| Warm Eclectic Bedroom Furniture | Pixelandbeans | CC-BY 4.0 | [OGA](https://opengameart.org/content/warm-eclectic-bedroom-furniture-set) / `da873b5f2152ff5cfafbe61d9eea6eef606a7aaf05660e0c6344e1f3dacdd3fe` | 1 PNG | 223×128 原图；未改像素；有床、书柜、椅子、地毯等 |
| Cottage Top-down Asset Pack | Lexaei | CC-BY 4.0 | [OGA](https://opengameart.org/content/cottage-top-down-asset-pack) / `ce51575824998d59bff5fdf6cbbc7d31d32ee7b82e8985a7442e82138a570f80` | 1 PNG | 440×256；**比例更细，未确认与 16px 同基准，未作为正式地图推荐** |
| Cozy Town derived actions | Spaceyyy（基础）+ 本项目修改 | CC-BY 4.0 | 基础 player 图 `772eaaeb9d71c63d54766eda5f3e3dba83c939f63f1224ac4909c72443b2e7b3` / 派生 `ea356891202d131888bbdc61a764f17428635ed9d6516c161fe5df60182586de` | 1 PNG | 从 4 个 idle 帧派生 stand/sit/read/rest；折叠腿部、加书、闭眼和 Z；不是第三方现成动作包 |

## 3. 转换记录

- **Animated Tiles**：原始下载文件实际为 JPEG 数据但扩展名 `.png`；转为真正 PNG，未改像素，否则 Godot `load_png_from_buffer` 会拒绝。
- **Animated Tree and Water**：原始图有白色和洋红背景；转 alpha，并把完全透明像素的 RGB 清零，避免线性过滤产生白边。
- **Basic Character Sprites**：原始洋红背景转 alpha；仍保留不规则图集布局，不用于正式地图。
- **Cozy Farm SFX / Forest Bird Sounds / Birds and Wind**：选段并转 OGG Vorbis；原始 WAV/OGG 未提交，减少仓库体积。
- **Cozy Farm Lite sheets/tileset**：直接复制 1x 合集图，未改像素；它们与独立 PNG 是同一原始包内的合集，不替代独立图块。
- **Cozy Town derived actions**：见 `characters/cozy-town-actions/SOURCE.md`；派生文件继续遵守 CC-BY 4.0 并署名。

## 4. 公开再分发结论

- 上述原始素材均可公开再分发：CC0 无需许可，CC-BY 4.0 需署名；
- 没有 CC-BY-SA、付费或禁止再分发的素材进入公开仓库；
- Cozy Farm / Cozy Town 的 **itch 商业完整包**没有下载或入库，只使用 OGA 的 CC-BY Lite 文件；
- 署名文本集中放在 `ATTRIBUTION.md`；
- 原始许可证文件位于各包目录，不能删除。
