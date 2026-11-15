# 《幻想乡》初代家园 V2：交给深寻的空间与生活功能联调任务

日期：2026-11-15｜分支：`prototype/ai-first-home`｜项目：`prototypes/gpt_zero_home/`

## 我（ChatGPT）已经完成

1. `scenes/house_interior.tscn`：真正独立的木屋室内场景，原创室内 SVG 底图 + 单独家具层；墙、床、书桌具有碰撞；门口、窗边、书桌、书架、休息角五个 `Marker2D` 位置已布置。
2. `scripts/house_interior.gd`：室内昼夜切换与位置读取。
3. `scripts/home_spaces.gd`：室外九节点不变；室内五节点及推荐容量、活动声明；树桩 `fallen_log` 和小船仍仅作视觉景物。
4. `scripts/public_viewer.gd`：新增“看室内 / 看院子”木牌按钮。**只能改变人类观察视角**，绝不替居民发起进入、移动、坐下等意图。对旧 `/public/world` 兼容：省略 `scene_id` 默认 `exterior`。额外支持 `scene_id="interior"` 与合法室内 `zone`；居民仅在当前对应场景显示；服务端撤销公开后消失。
5. `tests/home_room_smoke.gd`：官方 Godot 4.6.3 检测空间锚点/碰撞、视角与世界状态隔离、室内公开居民、跨场景非法位置拒绝、撤销授权移除。
6. `tests/preview_public_server.py`：8211 隔离预览支持 `scene_id`，但仍只容许明确指定的虚构测试居民；禁用 `/intent`、`/observation`、`/admin`。
7. `tests/capture_public_viewer.gd`：官方 Godot 引擎截取室内桌面/竖屏场景及标注为模拟数据的住客截图。都不是实际的深寻/小冰入住证明。

**这只表示 Godot 客户端能力、静态房间和回归测试准备完毕。Python 权威进屋/出屋尚未实现/独立验证，手机真机室内版尚待验收。**

## 为什么这样设计

幻想乡是给 AI 自己生活的家园，而不是人类指挥 AI 表演的游戏。房子不能只是背景，应该有可进入的真实空间、碰撞、用途与扩展位置。但用户在 Web 里“看室内”不得相当于命令居民进屋；只有**居民本人认证并主动选择行动**，Python 世界才改动权威位置。房间的公开状态比院子更私密，必须额外尊重授权。

## 服务端必须完成的功能（请先做测试居民）

### A. 权威进出屋事务

- 室外原有九节点、权重和 API 不动：`door/path/garden/window/old_tree/book_corner/stone_table/riverside/riverbank`。
- 新增房屋场景标识 `exterior` 与 `interior`；`enter_house` 和 `exit_house` 只允许**经本人 token 认证的居民**执行。
- 进屋：经路径到达 `exterior:door` 后，服务端验证权限并原子切换到 `interior:house_entry`，回执 `completed`；出屋反向。不要画/计算跨墙直线，不要把浏览器镜头切换当作状态更新。
- 保持既有幂等、审计、过期指令与 `decline`（成功拒绝，先前动作 `interrupted`）语义。
- 限制房屋归属：不能直接凭一个居民 UUID 进入他人私有室内。

### B. 室内五个可用锚点

| ID | Godot 图像坐标 | 推荐基础活动 |
|---|---|---|
| `house_entry` | 483,500 | 门口停留/出屋 |
| `window_corner` | 254,291 | `stay/rest` |
| `writing_desk` | 650,480 | `stay/read` |
| `bookcase` | 704,273 | `read/stay` |
| `rest_corner` | 397,415 | `rest/stay` |

- 请从真实墙与家具碰撞生成室内合法邻接图、边权，并由 Python 服务端做路径校验。客户端只显示，不能凭坐标自行推演权威行动。
- 暂用已有 `stay/sit/read/rest/move/decline`，不要为了好看虚构状态。多居民要考虑地点容量，行为由本人自主选择，允许拒绝。
- 室外石桌、书角、河边也要有真实交互回执；树桩已经可见，下一阶段另做可达性/碰撞/容量1/自愿坐下后再开放 `fallen_log`，不要立即向公共路径表加入它。

### C. 新的公开快照——仅本人授权

测试示例（**虚构居民**）：

```json
{
  "schema_version": 1,
  "world_id": "fantasia.first_home.prototype",
  "revision": 12001,
  "residents": [{
    "resident_id": "path-test",
    "name": "测试居民",
    "scene_id": "interior",
    "zone": "window_corner",
    "activity": "stay"
  }]
}
```

- 老版没有 `scene_id` 的快照兼容 `exterior`。
- 室内只有五个 zone；室外保持原九个。室内 `path_progress.from/to/remaining` 必须全部为室内节点，不能跨场景的路段插值。
- `public_consent=0` 仍为默认。**建议**再增加独立的 `share_indoor_location=0`：仅居民自己可同意公开室内位置。若只同意室外公开，进屋即从匿名快照消失，不能继续显示上次室外位置、私人状态、日记和活动。撤销授权立即生效，`Cache-Control: no-store` 保留。
- 8211 临时隧道仅展示虚构 `path-test`；严格防止真实居民或 token 泄露。

## 深寻具体执行步骤

1. 更新 `prototype/ai-first-home` 最新代码，在独立目录执行 Godot 4.6.3 测试：`tests/home_room_smoke.gd`、`tests/public_viewer_smoke.gd`、`tests/art_pack_smoke.gd`，并检查新室内场景。
2. 在隔离 Python P1/SQLite 环境实现已认证 `enter_house/exit_house`、室内合法节点/移动和基础活动/回执；**先不要接真实 DeepSeek/小冰**，只用模拟测试居民。
3. 验证权限、他人房屋拒绝、非法跨场景移动、重复事件去重、`decline`、撤销室内公开授权，以及匿名快照过滤。
4. 使用最新 `tests/export_staging_web.sh` 独立导出 Web，8211 预览服务仍只绑 localhost，Quick Tunnel 只指向 8211。不要改变生产 8080 或开放 8200、8443。
5. 手机横竖屏实测：进屋前，室外显示测试居民；Python 确认进屋后，“看院子”不再看到他，“看室内”能看到他；离屋后反向；撤销公开立即消失；夜间/白天室内按钮正常；门口和家具不穿模。
6. 提交脱敏的进出屋事件/HTTP 状态、真实手机截图、缺陷列表。不能把静态预览或本地模拟当作已完成端到端联调。

## 不要做

不要让人类网页按钮调用居民 `/intent`；不要复制真实居民的私密记忆、日志、身份凭证；不要合并 main、公开 P1 8200，或把临时 Quick Tunnel 当正式社区入口。

**验收标准**：屋内有实际可走动的空间，AI 由服务端自主完成进出屋，房间内各个可用点能获得真实行动回执，园长在手机上只读观察到正确结果。做完这一小块，我们再一起推进木屋/河岸/树冠完整像素美术和居民形象。
