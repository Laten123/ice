# 002 第二轮视觉样张：C 路线（待审查）

本轮只制作实际 PNG 合成样张，不修改 Godot 场景、运行代码、原始素材或001；不合并、不上线。基线：`3fb887a9c8efceec0b151084d5ae61b4d0adf4ca`。样张不是 Godot 运行截图，也不是布局示意图。所有景物来自仓库已有 PNG 的实际像素，未使用生成式重绘。

## 交付

| 样张 | 原生版 | 最近邻4倍版 |
| --- | --- | --- |
| 室外26×17格 | [416×272](outdoor-1x.png) | [1664×1088](outdoor-4x.png) |
| 室内14×11格 | [224×176](interior-1x.png) | [896×704](interior-4x.png) |
| 人—门—椅—床比例对照 | [416×176](proportions-1x.png) | [1664×704](proportions-4x.png) |

室外把完整木屋放在上方偏中，门前小路连接入口与左侧阅读角；右侧菜地、花圃，左下小水景。使用短围栏、松树和低矮植物表示边界，保留空隙。基础草地降低纹理对比，避免原地图的高频重复噪声。角色、建筑、家具始终按原生像素密度贴入，没有各自拉伸。

室内是完整独立画面：木质地板、后墙、两侧墙、底部出口、窗户、床、书柜、书桌、椅子、灯与植物。阅读位和站立位展示两位同皮肤居民的生活位置，不表示复制了绑定居民身份。中央留出地毯与通路；没有覆盖室外截图。

## 素材及许可

| 使用内容与仓库路径 | 作者及原始来源 | 许可与履约 |
| --- | --- | --- |
| `assets/vendor/buildings/cottage-topdown-optional/cabin.png`：木屋、松树、长椅、岩石、草丛、野花、窗户裁片 | Lexaei，[Cottage Top-down Asset Pack](https://opengameart.org/content/cottage-top-down-asset-pack) | CC BY 4.0；原许可保留于素材目录；本轮进行了裁切和调色 |
| `assets/vendor/interiors/cottage-core-furniture/cottage_core.png`：床、书柜、桌、凳、灯、地毯、植物 | Pixelandbeans，[Cottage Core Bedroom Furniture](https://opengameart.org/content/cottage-core-bedroom-furniture-set) | CC BY 4.0；原许可保留；裁切、统一色调，未改变物件尺寸 |
| `assets/vendor/terrain/cozy-farm-lite/`：草地、道路、围栏、灌木、花、作物生长帧 | Bramble & Byte / roberto mellado，[Cozy Farm Lite](https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen) | CC BY 4.0；只使用已有Lite文件；调色、草地降对比，未使用付费完整版 |
| `assets/vendor/buildings/cozy-town-lite/characters/player-1-walk.png`：人物原始帧 | Spaceyyy，[Cozy Town Lite](https://opengameart.org/content/cozy-town-lite-%E2%80%94-16x16-top-down-street-tiles-caf%C3%A9-and-walking-character) | CC BY 4.0；人物原始帧16×24，本轮未缩放角色 |
| `assets/vendor/characters/cozy-town-actions/actions_sit_read_rest.png`：坐、读、休息姿态实验 | Spaceyyy基础角色＋项目已有派生修改；修改说明见该目录SOURCE.md | CC BY 4.0；沿用原有署名，并裁掉相邻帧残片。本轮只是静态姿态，不宣称完成动画 |
| `assets/vendor/interiors/interior-spritesheet/interior_0.png`：地板与墙体裁片 | InThePixel，[Interior Spritesheet](https://opengameart.org/content/interior-spritesheet-16x16-tiles) | CC0；裁切组合、调色 |
| `assets/vendor/animations/animated-flowing-water/water_strip13.png`：小水景 | InThePixel，[Animated Flowing Water](https://opengameart.org/content/animated-flowing-water-2d-16x16) | CC0；仅取第一帧，调色并用像素轮廓遮罩组成池塘；不宣称水面动画完成 |

以上来源的许可原文、署名资料已经在仓库素材目录保留，未删除或替换。CC BY 4.0允许修改、公开再分发，必须保留作者、来源、许可证及修改说明：[法律文本](https://creativecommons.org/licenses/by/4.0/legalcode.en)。[CC0法律文本](https://creativecommons.org/publicdomain/zero/1.0/legalcode.en)。本表和sources.json随派生样张分发。

## 可复现的统一处理

`build_samples.py` 只读已有PNG，输出本目录的样张和清单。依赖Pillow；比例说明文字使用系统Noto Sans CJK字体（仅渲染文字，不复制字体）。从工程根目录执行：

```sh
python3 docs/art-review/round2/build_samples.py
```

- 以16px为布置坐标；建筑和家具是跨多格物件，不假装所有原图都是16×16小图块。
- 逐像素HLS色板映射：木屋提亮并从暗红转暖棕，树木降低饱和度，水面改为低饱和蓝绿，家具稍降饱和度。公式在脚本中固定，没有抗锯齿或模糊滤镜。
- 阴影统一向右下偏移3px、12%透明度，由对应物件的原始alpha派生；没有使用原包里大块纯黑投影直接覆盖画面。该二维阴影仍需审查，不当作最终光照效果。
- 地面使用原草地最常用底色和低对比原草纹叠印；道路使用原道路边角。水景岸边由道路原图与阶梯形像素遮罩合成。
- 卧床对照用既有休息帧的头部与原床被面分层遮挡，不放大角色或床。坐姿和阅读沿用已有静态派生姿态。
- `sources.json` 逐项记录原始PNG路径、SHA256、裁切坐标、调色类别；原始文件未经修改。

## 比例结论与尚未通过的细节

这套原生比例可以继续作为审查基线：人物16×24画布，木屋裁片143×114，凳19×23，床53×60。床是双人床，不以单人床比例评判。人站门前、坐位与床铺的相对大小已同屏展示。

不能把本轮样张直接标为正式美术完成：

1. 需要补绘真正的室内窗框与窗台，目前复用外窗裁片，有外墙梁和花箱特征。
2. 阅读凳的靠背、手、书和腿的前后关系还需细化；现有派生24px帧包含邻帧残片，本轮只裁掉残片，没有把它包装成完整动画。
3. 卧床头部与枕头的接触、被面遮挡，以及进入/离开床铺的过渡，需要后续补帧。
4. 屋檐、树根接地阴影与水岸细节仍可精修；当前统一投影是比例审查用的简化二维投影。
5. 地板图块本身较规整，后续若仍显砖纹，应替换成真正更自然的木板纹，不能单独非等比放大来掩盖。
6. 两位居民共用源皮肤，仅作姿态与空间测试；未来皮肤资源应与居民UUID和模型UUID分离。

## 验证

- 重新运行既有Godot4.6.3测试：129/129通过，见`godot-baseline.txt`；这只证明本轮未破坏既有代码，不是美术质量通过。
- 三组4x PNG均验证为1x PNG的精确NEAREST复制；没有插值颜色。验证结果见`validation.json`。
- 清单中所有源PNG的SHA256与仓库原文件一致。
- 人工查看了室外、室内和比例对照的实际放大输出；本轮没有生成或声称生成新Godot场景运行截图。
- 未修改项目入口、身份、私聊、UUID、寻路、动作控制器、001、工作流、原始素材或线上部署。

等待这组三张像素样张的视觉审查；确认后才进入TileMapLayer/Sprite2D/AnimatedSprite2D场景实施。
