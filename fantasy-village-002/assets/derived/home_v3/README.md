# 002 第三轮派生资源与署名

这些 PNG 均由仓库已有合法源图裁切、调色、分层或项目补绘生成，未下载新增素材。原图与原许可没有被覆盖。`sources.json`记录源文件 SHA256、裁切和调色；生成器是 `tools/build_home_art.py`（依赖 Pillow）。所有角色仍为原生16×24像素，放入32×40透明动作画布，不放大角色或家具；运行时最近邻过滤。

| 派生内容 | 作者、原始素材与许可 |
| --- | --- |
| house/pine/tree/bench/rock，以及部分花草 | Lexaei，[Cottage Top-down Asset Pack](https://opengameart.org/content/cottage-top-down-asset-pack)，[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。源与许可：`assets/vendor/buildings/cottage-topdown-optional/`。裁切、暖棕/柔绿调色；树冠1px摆动，长椅前沿分层。 |
| bed/blanket/bookcase/desk/chair/lamp/rug/plant | Pixelandbeans，[Cottage Core Bedroom Furniture](https://opengameart.org/content/cottage-core-bedroom-furniture-set)，CC BY 4.0。源与许可：`assets/vendor/interiors/cottage-core-furniture/`。裁切、调色；床被面/凳前沿分层，地毯裁小。 |
| walk/idle/sit/read/rest/tea/open_book/close_book/sit_down | Spaceyyy，[Cozy Town Lite](https://opengameart.org/content/cozy-town-lite-%E2%80%94-16x16-top-down-street-tiles-caf%C3%A9-and-walking-character)，CC BY 4.0。源与许可：`assets/vendor/buildings/cozy-town-lite/`。四方向原生6帧行走；Codex项目派生闭眼、呼吸、屈膝、翻页、书本开合、杯子动作。动作质量与帧类型见 `docs/round3/README.md`。 |
| exterior_ground道路、土壤、田垄、作物、短围栏及flowers | Bramble & Byte / roberto mellado，[Cozy Farm Lite](https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen)，CC BY 4.0。源与许可：`assets/vendor/terrain/cozy-farm-lite/`。原生瓦片组合与调色；草地低对比连续色差、局部草纹、台阶/岸线/接地阴影为项目派生。 |
| water_0..12 | InThePixel，[Animated Flowing Water](https://opengameart.org/content/animated-flowing-water-2d-16x16)，[CC0](https://creativecommons.org/publicdomain/zero/1.0/)。源与许可：`assets/vendor/animations/animated-flowing-water/`。采用原13帧、调色、岸线遮罩、深水线。 |
| interior_ground/window/chimney/smoke/tea_table及补绘像素 | Codex为本项目制作；室内木板、窗框、烟囱、烟团与茶桌，使用上述源色板，无生成式图像。作为项目美术派生按CC BY 4.0分发，保留涉及原作署名。 |

CC BY 4.0允许修改和公开源素材再分发，必须保留作者、来源、许可与修改说明。以上表格及原目录许可证须随派生图保留；不能把这些派生图当作未修改原版。许可证法律文本在来源链接和仓库既有审计记录中保留。来源助手读取的旧动作实验也可能出现在清单中，当前运行动作直接从Spaceyyy原人物帧派生，并不使用旧静态动作条作为完整动画。

临时UI字体没有放在本目录：仍为已获用户允许的Noto CJK子集，`assets/ui/placeholder_ui.otf`；OFL原文 `LICENSES/NOTO-CJK.txt`。本轮补齐新增提示所需字形，构建工具检查源码可打印字符覆盖。
