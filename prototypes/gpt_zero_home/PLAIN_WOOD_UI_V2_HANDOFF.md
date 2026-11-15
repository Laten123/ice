# 幻想乡 · 简约木牌 UI V2（园长审美反馈后修正）

**决策**：园长看过手机实机版后认为旧的金色浮雕与花枝过于华丽，想要像木牌一样朴素的乡村游戏 UI。旧 V1 美术资源可以保留作素材档案，**不再默认展示**。

## 已提交（可测试，不是概念图）

- `scripts/fantasia_ui_skin.gd`：正式换为**程序生成的简约像素木牌**。标题与上午／黄昏按钮只使用暖棕色木板、深色边缘、极淡木纹、少量木钉，不再用鲜艳金边/大块花藤/紫色宝石。四个状态：普通/悬停/按下/禁用；每个材质只生成 112×42 像素的小贴图，9-slice 拉伸。无需新 PNG、额外网络或服务器 GPU。
- `scripts/public_viewer.gd`：底部按钮文字由 `上午（预览）`、`黄昏（预览）` 精简为 `上午`、`黄昏`，增大字体尺寸；标题缩短成 `幻想乡 · 初代家园`，并用深绿色衬底代替画面外的纯灰色。保持昼夜切换的原有按钮信号、同源 HTTPS 公开快照、树桩、字体 fallback、居民只读权限。
- 开放像素字体预留：如果工程存在 `res://art/fonts/FusionPixel12.woff2`，观察器优先使用它；否则保持已手机验证可显示中文的 `NotoSansSC-VF.ttf`。字体路径配置已经接入，但**当前还没有把 Fusion Pixel 字体下载、授权文件和打包脚本交付或做手机真机验证**，不要宣布像素中文已经解决。
- `tests/public_viewer_smoke.gd`：回归检查 112×42 的内存木牌材质、标题和两个短标签，不允许自动退回旧花枝贴图。原有 Python 快照、授权、移动和只读测试继续保留。
- 旧 `art/ui/` 中的华丽 PNG 不删除，以便将来素材创意工坊有别的风格可选；V2 不再默认读取它们。

## 字体授权原则（请深寻遵守）

**推荐 Fusion Pixel Font / 缝合像素，12px Proportional（简体中文字形）**。其官方字体采用 SIL OFL-1.1，可以嵌入和修改/子集化，但修改后的字体不得违反保留字体名称条款；请同时保留 OFL 授权文本及必要上游许可。具体版本先固定，再提供源 URL、SHA256、解包内容、最终 WOFF2 体积。官方仓库：

https://github.com/TakWolf/fusion-pixel-font

Godot 4.6 支持 WOFF2 字体。测试时先使用完整官方简体中文 WOFF2（不要盲目对子集裁掉居民可能取的名字）；在**独立 staging 工程**加入 `art/fonts/FusionPixel12.woff2`，连同其官方 OFL 许可一起打包。完成后以真机截图验证“幻想乡 / 上午 / 黄昏 / 深寻 / 小冰 / 任意测试昵称”都不出现方框。

**不要使用 Zpix 作为开源默认字体**：作者公开许可仅个人/教育用途免费；商业授权需另购，且禁止修改、转换和拆分。即使幻想乡目前非商业，也不适合给未来开放分发的作品增加许可障碍。

- Zpix 官方许可证：https://github.com/SolidZORO/zpix-pixel-font
- Fusion Pixel 字体许可证：https://github.com/TakWolf/fusion-pixel-font/blob/master/LICENSE-OFL
- Godot FontFile 支持：https://docs.godotengine.org/en/4.6/classes/class_fontfile.html

## 深寻现在执行

1. **拉取** `prototype/ai-first-home` 最新提交到隔离测试目录，确保 `fantasia_ui_skin.gd` 是 V2 内存生成木牌代码，而非先前调用 `art/ui/title_floral.png` 的旧版本。
2. 运行官方 Godot 4.6.3 headless 项目导入、`tests/public_viewer_smoke.gd`、`tests/art_pack_smoke.gd`。新木牌不是一次性的美术图，也不需要改变原 AI 公共快照 JSON。
3. 使用现有 `tests/export_staging_web.sh` 导出 Web；因为没有增加新美术 PNG，此阶段仍可先保留 Noto Sans SC，完成 UI 木牌手机实测。只将公网 Quick Tunnel 指向临时 `127.0.0.1:8211` 预览，绝不直接指向 8200。
4. **两张真实手机截图**：一张竖屏、一张横屏。检查木纹不花哨、按钮汉字足够大、标题牌不挡调试与人物、树桩和石桌旁 `path-test` 均在。
5. 第二轮才引入合法授权 Fusion Pixel 字体到隔离副本，并比较启动包大小/加载速度、中文显示和动态居民昵称。暂不关闭 Noto fallback，直到手机字体验收通过。
6. 保持只读、居民默认不公开。**严格维持 8200 仅回环、8211 隔离预览、生产 8080 未变**，不合并主分支、不动生产。

**验收口径**：先让园长确认“就是普通木牌的感觉”，再考虑是否需要进一步简化；不再为了华丽而增加金边和花枝。 
