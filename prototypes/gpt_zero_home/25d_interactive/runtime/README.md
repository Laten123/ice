# 幻想乡 · V7 Godot 源码开发工程

本目录从已认可的 **V6** 完整工程展开，后续在这里开发、测试并提交代码。引擎固定 **Godot 4.6.3**。

直接打开 `project.godot`，开启「测试：开」，选择地点并执行离线生活动作。默认不显示居民、不连接真实模型。两张已认可原图保持原始字节与分辨率。

本轮加入独立水面、8 个按脚底深度遮挡的环境图层，以及可换四向像素皮肤的居民关节骨架。支持走路、坐下、发呆、阅读、休息、进出屋。当前人物是已有测试人偶；正式角色皮肤与逐物件对位继续精修。

```bash
python3 -m pip install -r tests/requirements.txt
python3 tools/check_runtime.py
godot --path .
```

运行 Godot 本身不需要 Python/Pillow；这些依赖只用于离线素材构建与测试。实际渲染检查、设计范围和深寻的交接见 [V7_DEVELOPMENT_HANDOFF.md](V7_DEVELOPMENT_HANDOFF.md)。原图与动态缺项基线见 [V6_ENVIRONMENT_AUDIT.md](V6_ENVIRONMENT_AUDIT.md)。

`index.html` 保留 V6 浏览器预览；V7 的动画与分层以本 Godot 工程为准。Android 手机布局与触控由深寻负责。历史 V4/V5/V6 文档和上级 ZIP 为可追溯基线，不再是当前源码编辑入口。
