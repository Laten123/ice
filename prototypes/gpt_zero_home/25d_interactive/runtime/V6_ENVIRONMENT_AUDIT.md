# 《幻想乡》初始家园 V6：环境动态缺项审计与修复

日期：2026-11-15。范围：只改环境表现，不承担 Android 布局/缩放（深寻负责），不接入 DeepSeek/小冰等真实 AI，不动正式世界的地点和权限。

## 逐项审计（基于 V5 源码和认可的两张原始 PNG）

| 景物 | V5 实际状态 | V6 改动 | 仍待后续 |
|---|---|---|---|
| 老树冠 | 只有树冠**内部纹理** 1–2px 微摆，外轮廓仍静止 | 保留低频内部摆动和地面阴影，避免整图移动 | 树冠前景/树枝完整分层 + 与人物的真正遮挡 |
| 树下悬挂灯笼 | 光晕中心移动，**灯笼本体完全静止** | 从原图提取独立透明灯笼；覆盖原图旧灯笼的小块干净底图，围绕真实悬挂点约 ±2° 摆动，悬挂绳同步变化；保留原始批准 PNG 字节不变 | 如需更大风幅，再拆完整吊链；目前仅轻微风摆 |
| 河面 | 少量安全区域的亮线，临岸水面和码头边缘层次不足 | 增加经原图像素验证的 17 个水面小反光点，另加 4 组泊船周围逐渐消失的弧形水波；与日夜色调协调 | 完整河面图层、水流方向与局部深度动画；船仍系泊、没做船体自由摆动 |
| 烟囱烟 | 烟雾上升但多数向固定方向飘，风感与树不同步 | 羽化烟团结合双周期阵风转向；原烟囱位置不变 | 还可做烟灰亮暗、屋顶后方遮挡细化 |
| 房间与屋外窗户 | 黄昏全场偏冷时，**窗玻璃跟着褪色** | Godot shader 在三处室外暖窗和室内灯芯设置局部 emissive 保护；浏览器对窗格局部重绘暖光，仍保持 2.8s 渐变 | 真正贴图灯罩分层、屋内窗外视差和窗帘布料骨骼 |
| 室内光束、灰尘 | 已有缓慢移动的光束与尘点 | 保留，关闭动态时停止浮尘，昼夜过渡独立 | 窗帘实体摆动、微风下盆栽枝叶/布料独立动画仍未做 |
| 花草与落叶 | 叶片飘落、亮点轻微呼吸，**花和草仍画在底图** | 保留安静的局部动态，避免在整图上制造重影 | 花丛/草叶真正分层才可自然摆动 |
| 天空与云 | 云完全静止，黄昏色变化 | 暂不强制移动云：原图是整张底图，移动裁块会产生明显重影和缝线 | 云层素材分离后再做视差，不用整图滑动假装云动 |
| 居民/模型 | 只读公开、离线测试人偶，尚无动作骨架 | **本轮不接入**，不改变地点身份 | 环境合格后才做通用人偶骨架、动作与皮肤 |

## V6 的核心实现

- **原始图片零修改**：`art/home_25d_exterior.png` SHA-256 `016032f3513f688d762d9ffbf5cc86ad4d13c2b18f52fb68b2b0d7954a4a4610`，`art/home_25d_interior.png` SHA-256 `4ab46b9870e25e653f4fb94f79fa03c30cce27e55e6f24be724458e12895054b`。
- 新 `art/layers/tree_lantern_clean_plate.png`（77×104）和 `tree_lantern_sprite.png`（72×85），仅局部覆盖旧静止灯笼，不重画木屋和老树。素材的可重建脚本 `tools/build_lantern_layers.py` 是**离线美术构建工具**，使用 OpenCV/Pillow；**Godot 和浏览器运行不需要这些依赖**。
- 在 `scripts/home_25d_atmosphere.gd` 和 `web/ambient_25d.js` 添加独立灯笼摆动、泊船旁局部水波、真实水面反光、同频风向烟雾。`shaders/home_25d_wind.gdshader` 增加暖窗遮罩。交互锚点、室内外、服务端读写路径均不改变。
- 不将灯笼、树影或水波添加为新的可交互点，不制造活动意图。

## 验证顺序

```bash
python3 tests/source_audit.py
node tests/ambient_browser_smoke.mjs
node tests/environment_v5_smoke.mjs
node tests/environment_v6_smoke.mjs
# Godot 4.6.3:
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/first_home_25d_smoke.gd
godot --headless --path . --script res://tests/ambient_godot_smoke.gd
godot --headless --path . --script res://tests/environment_v5_smoke.gd
godot --headless --path . --script res://tests/environment_v6_smoke.gd
```

CI 自动核对：原图 SHA、不变的地方/公共权限、灯笼小图尺寸、灯笼旋转变换、关掉动态时停止物理装饰、仍能执行日夜过渡，以及 Godot Shader/GDScript 导入和实际场景测试。

**需要深寻实机检查而不是静态测试推断的内容**：灯笼原位是否出现黑边/接缝、树冠是否在某些角度重影、水波是否越出河岸、Android 30/60fps 帧率及横屏全屏/捏合缩放。深寻负责手机适配，但不应未经同意重新画素材。