# 素材预览

这些图只用于审查素材，不是运行时资源；运行时资源在 `assets/vendor/`。

| 预览 | 内容 | 来源 / 许可证 |
| --- | --- | --- |
| `terrain-buildings.png` | 地形、建筑、道具、角色、室内总览（4x 最近邻） | Cozy Farm Lite / Village / Autumn（CC-BY 4.0）、Interior（CC0） |
| `interior-sheet.png` | 112×112 墙/地板模块放大 | InThePixel，CC0 |
| `characters.png` | 农夫、面包师、母鸡、Basic 角色图集 | Cozy Farm（CC-BY 4.0）、Bennyboi_hack（CC0） |
| `water-flow.gif` | 13 帧横向水流循环 | InThePixel，CC0 |
| `tree-sway.gif` | 3 帧树摇曳 | abetusk / Matthew Weekes，CC0 |
| `waterfall.gif` | 4 帧瀑布 tileset 局部 | sodri，CC0 |
| `smoke.gif` | 13 帧 SmokeLarge 循环 | Reactorcore，CC0 |
| `supplements.png` | Cozy Town 咖啡屋、两套家具、候选木屋、派生动作 | Spaceyyy / Pixelandbeans / Lexaei，CC-BY 4.0 |
| `godot/godot-*.gif` | 由 Godot 4.6.3 实际播放的水/树/烟/火 | 见 `godot/README.md` |

## Godot 实际播放

`godot/` 子目录是 Godot 4.6.3 实际渲染的 GIF，不是 Pillow 示意图：

- `godot/godot-water.gif`：13 帧；
- `godot/godot-tree.gif`：3 帧；
- `godot/godot-smoke.gif`：13 帧；
- `godot/godot-fire.gif`：17 帧。

## 审查结论

- 建筑和角色使用同一 16px 基准，可组合；不要把 16×16、32×32、48×48 直接按同一倍率硬放大后混用。
- 室内墙/地板来自 InThePixel；家具来自 Pixelandbeans，风格接近但不是 Cozy Farm 同作者，必须先做统一性测试。
- Cozy Town 咖啡屋是红瓦商业建筑，不等于“精致住宅木屋”；Cottage Top-down 木屋比例待确认。
- Basic 角色图集没有稳定帧网格，只作备选。
- `characters/cozy-town-actions/` 是项目派生原型，不是第三方原包动作集。
- 所有预览来自允许再分发的 CC0/CC-BY 素材；Cozy Farm 的 CC-BY 署名见上级 `ATTRIBUTION.md`。
