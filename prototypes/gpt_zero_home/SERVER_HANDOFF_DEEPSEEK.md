# 🌿 致深寻：GPT 独立家园样板——阿里云测试交接

> 本文是给深寻的工作交接，不是线上部署申请。请先运行独立测试，不要触碰任何正在运行的 `幻想乡` 服务器服务。

## 目标与当前状态

我们已在 `Laten123/ice` 的独立分支 `prototype/gpt-zero-home` 放置了从零编写的 Godot 4.6.3 家园样板。**不能**在仓库根目录直接以 `project.godot` 打开：那个工程属于旧世界。请进入 `prototypes/gpt_zero_home/` 子目录。

内容包括独立 SVG 场景（木屋、河岸石桌、老树、书架、小木船）、上午与黄昏两种光照版本、手机触摸按钮、竖屏左右滑动、横屏自适应以及电脑键盘入口。未使用原 `scripts/main.gd`、`assets/`、`tiles/` 或后端。

**我们尚未完成**真实角色移动、室内、AI、自主对话、水面动态、Android 原生应用、Web 浏览器触摸的实机验收；不能把「能截图」当成成品。

## 阿里云隔离验证

建议在服务器新建临时目录，绝对不要覆盖现有生产目录、数据库、HTTPS 证书或服务进程。

```bash
TEST_DIR="$(mktemp -d /tmp/fantasia-gpt-clone.XXXXXXXX)"
git clone --single-branch --depth 1 \
  --branch prototype/gpt-zero-home \
  https://github.com/Laten123/ice.git \
  "$TEST_DIR/ice"

# 不进服务器正在运行的 /root/fantasia 等旧项目目录
cd "$TEST_DIR/ice"
git rev-parse HEAD
bash prototypes/gpt_zero_home/tests/server_verify.sh
```

默认尝试使用 `godot` 或 `godot4` 命令。若 Godot 4.6.3 是手动下载的，使用

```bash
GODOT_BIN=/absolute/path/to/Godot_v4.6.3-stable_linux.x86_64 \
  bash prototypes/gpt_zero_home/tests/server_verify.sh
```

脚本会在 **/tmp 新建副本** 中导入资源、运行基础触摸与响应式布局测试、尝试通过 xvfb 截取四张实景图片；截图和日志都留在脚本输出的新目录中。脚本**不做 git push，不使用生产数据库，不启动后端或监听网络端口**。可在测试完成后手动清理这两个新建的临时目录。

截图预期文件：
- `preview-morning.png`：960×600 桌面上午
- `preview-dusk.png`：960×600 桌面黄昏
- `preview-phone-landscape.png`：853×384 横屏
- `preview-phone-portrait.png`：390×844 竖屏

若 `xvfb-run` 缺失，脚本只做 Godot headless 检查并提示跳过截图，不代表整套显示检查通过。

## 请深寻重点审查

1. **真实画面**：是否有拉伸、裁切、空白边框、UI 遮挡？河流、木屋、石桌、小冰窗台、书架等比例是否符合45°斜视的生活场景？
2. **横竖屏**：上午／黄昏按钮是否都在安全位置，至少容易触摸；模拟宽度与实际浏览器的安全区域仍需区别。
3. **时间切换**：上午和黄昏能否通过实体/虚拟点击正常切换？颜色变化是否自然？
4. **交互真实度**：竖屏滑动与按钮是否冲突？服务器 xvfb 无法替代 Android 真机的多点触摸，请明确标注未实测部分。
5. **质量判断**：它目前还是SVG形状堆叠的独立展示原型，不是合格的像素素材体系。请直接指出视觉距离精品场景还差在哪里。
6. **低配置**：报告 Godot 版本、内存峰值（若能测得）、CPU和导入时间，不要凭感觉说「能跑很多人」。目前是单场景、无后端。

## 交付给主人的报告

请用明确的 ✅/⚠️/❌ 区分「引擎检查通过」「模拟视口截图」「真机触摸已测」。报告：当前 commit SHA、启动命令、四张截图路径、日志、失败错误及复现方式、你的独立美术评价和下一轮的优先修复建议。

只需要做**阿里云隔离测试**；未经主人另行批准，不改 `main`、`rebuild/v1`，不清理生产服务、不用新证书做实验、不部署公共端口。你有服务器管理权，测试范围由你把关。

—— ChatGPT
