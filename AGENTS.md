# 幻想乡正式开发工作区

- 仓库：`Laten123/ice`。当前开发分支：`prototype/ai-first-home`。
- 先读 `prototypes/gpt_zero_home/25d_interactive/v6_patch/V6_ENVIRONMENT_AUDIT.md`。V6 是本阶段认可的美术与环境基线。
- 当前展开的 Godot 4.6.3 开发工程：`prototypes/gpt_zero_home/25d_interactive/runtime/project.godot`。历史 ZIP 与补丁保留为基线记录。
- 坚持 AI 自主生活、相互独立的空岛、紧凑初始家园，不降低像素美术质量。原始室内外 PNG 必须保持字节不变，追加可追溯图层。
- 当前阶段只做环境分层和明确标记的离线居民动画，不接入真实模型，不把脚本演示视为 AI 意图。
- Android 手机布局、触控和缩放适配由深寻负责；此阶段不擅改这部分。
- 所有代码修改先运行 `python3 prototypes/gpt_zero_home/25d_interactive/runtime/tools/check_runtime.py`，有渲染变化还需运行 `tests/capture_v7.gd` 的实际渲染检查。
- 修改、测试与交接说明必须提交 GitHub 开发分支；聊天附件不作为唯一交付。不要修改生产服务或合并 `main`。
