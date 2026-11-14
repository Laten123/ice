# 最新接口进展：深寻 P1 公共快照与 decline 修正

**依据**：拿铁转交的深寻后续实测报告；DeepSeek 服务器源码与端口 8200 未在本会话中直接访问。这份记录不等于已完成真实网络联调。

深寻确认：
- `decline` 返回 `completed`（detail: declined），被中断的旧移动返回 `interrupted`，SQLite 与 HTTP 状态一致。
- **真实新增** `GET /public/world`，匿名只读，字段 `schema_version/world_id/revision/residents`；`/observation` 和 `/intent` 无居民 token 仍为 401。
- 居民移动时报告扩展 `path_progress: {remaining: [...], progress: 0.0}`，其余公开字段为 `resident_id/name/zone/activity`。

Godot 侧配套修改：
- `scripts/public_viewer.gd` **只允许 HTTPS 的 `/public/world` 公开端点**，不接受 `http://127.0.0.1:8200`、私有 `/observation` 或 `/intent`；默认 `public_feed_url=""`，工程不会自动联网。
- 接收并检查 `path_progress.remaining`（有效的公共地点 ID、最多 24 项）及 `progress`（有限 0..1 浮点），拒绝未知/私人字段。
- `scripts/observer_sprite.gd` 根据每次公开快照给出的**权威 `zone` 位置更新角色**，取消从旧点向任意新点直线插值，以免穿墙；显示剩余路点数量。
- **重要未决**：`progress` 的物理语义未定义——它表示哪一条 `from→to` 边的进度？`remaining` 是否包含当前位置？报告中的 `path → book_corner` 与当前 Godot 图的 `front_path → river_path → tree_path → book_corner` 并非直接相连。**不得随意用两个显示点连直线**。本版只用进度元数据，不擅自进行分段动画。建议深寻下一步明确带边 ID 的 `current_segment: {from, to, progress}`，并与可视地图的路由拓扑统一。

## 真正用手机验证前还有两件事

1. 阿里云的 `127.0.0.1:8200` 仅服务器本机可访问；手机浏览器中的 `127.0.0.1` 是**手机自己**，不是阿里云。不能把测试 HTTP 端口直接设进 Godot Web，更不应为此对公网打开原始 8200 服务。由深寻确认在隔离/受控环境提供合适的 HTTPS 同源只读反向代理（含 CORS、缓存策略和匿名可见性审核）；HTTPS 接口的确切地址仍未知，不得凭空填写。
2. **匿名公开并不等于所有居民自动同意公开**。公开端点必须只包含居民已经授权展示的身份、地点、活动；隐藏或私密状态不得出现在匿名接口，服务器还应控制访问频率与最小日志暴露。

在公开 HTTPS 地址及可见性规则获得确认之前，Godot 侧只通过离线快照自动测试；**未声称已连上深寻的真实网关，也尚未接入真实模型。**

---

# 深寻 P1 v2 → Godot 只读公开观察器：技术交接

**来源**：拿铁转达的深寻 P1 v2 测试报告。报告称 Python stdlib + SQLite 网关已在 /tmp 隔离部署，支持原生路径模拟、completed/interrupted、token 撤销与限流。**本次尚未取得 P1 v2 源码，也没有直接访问深寻阿里云服务；上述能力属于深寻报告，不代表 ChatGPT 已经端到端实测。**

**分支**：`prototype/ai-first-home`  
**独立项目**：`prototypes/gpt_zero_home/`

## 1. 已完成的 Godot 侧只读展示代码

- 默认入口已切换为 **`scenes/public_viewer.tscn`**，人类进入 Godot/Web 后只看画面，不会启动本地居民决策/模拟器。
- `scripts/public_viewer.gd`：从**经过服务端隐私过滤的公开快照**建立视觉角色、渲染公开活动与场景光照；手机横竖屏布局支持观察，不给居民下命令。
- `scripts/observer_sprite.gd`：纯视觉居民，不带寻路指令、`accept_intent`、身份令牌或事件提交接口。两帧之间的平滑移动仅仅是**客户端视觉插值**；真实位置和行动结果一律以 Python 世界执行器为准。
- `tests/fixtures/public_world_v2.json`：人为构造的**公开**快照，用于不联网的 UI 演示，**不是真实深寻/小冰的自主行动**。
- `tests/public_viewer_smoke.gd`：拒绝私有字段、非法地点、重复 UUID、过期 revision，确认灯光 UI 不影响任何真实行动，检查手机横竖屏。
- 默认 `public_feed_url=""`：**完全不请求网络**，显示“尚未连接公开世界快照”。只有将来明确配置一个实际存在的**公开 HTTPS 地址**后才可能拉取数据；没有把测试端口 8200 内网地址写入工程。

## 2. 目前尚不存在的关键接口

深寻报告中的 `GET /observation` 是**居民凭证接口（X-Resident-Token）**，不能给供人观看的 Web 前端调用。

需要深寻实现并审查一个**独立公开/按访客权限过滤的只读快照接口**，例如 `GET /public/world`。此路径**仅为待确认的建议**，不是声明已经存在。服务端应只输出居民主动允许公开的内容；若需登录观看，也应该是访客会话授权，不是冒用居民 token。

拟议的**最小快照**：

```json
{
  "schema_version": 1,
  "world_id": "fantasia.first_home.prototype",
  "revision": 42,
  "residents": [
    {
      "resident_id": "00000000-0000-4000-8000-000000000001",
      "name": "深寻",
      "zone": "stone_table",
      "activity": "sit"
    }
  ]
}
```

公开字段必须最小化，未获授权的居民不能出现在此快照中。现有 renderer 只接受 `resident_id`、`name`、`zone`/`pos`、`activity`/`action`；状态 `idle`、`moving` 兼容映射为 `stay`、`move`。顶层仅收 `schema_version`、`world_id`、`revision`、`residents`。未知/私人字段整包拒绝，防止误展示。

公共位置：`door/path/garden/riverside/old_tree/book_corner/stone_table/riverbank/window`；`fallen_log`（**一根树干**）仍未画成可用的交互物体，因此不应通过公开可达位置服务端宣布为可走。

**注意**：只推送稀疏地点时，客户端会做直线插值，可能穿过视觉遮挡。正式版应提供每个可信执行器 tick 的完整公开坐标（需新增设计并验证）或带路径节点的公开插值数据，且把树干、房屋、树木分前后图层。现在只是接口/渲染路线证明。

## 3. v2 `decline` 回执语义需要修正

深寻测试日志：

```text
move(f1) -> moving
decline(f2) -> rejected + interrupted_event=f1
receipt(f1) -> interrupted
数据库: f1=interrupted, f2=rejected
```

真实含义应是：

- `f1` 被主动中断：`interrupted` ✅
- `f2` **居民主动拒绝/停止**，服务器成功执行：应该 `completed` 或返回 `accepted` 随即转为 `completed`，**不应**存成 `rejected`（那表示服务器拒绝了居民的有效意愿）。
- `rejected` 仅用于**非法/未授权/不可能完成的意图**；不能把居民行使“拒绝权”写成系统失败。
- 禁止后台任务调度器在收到 `decline` 后自动重新派发旧任务。拒绝后再次出发只能是该居民自主发出一个新的意图。

## 4. 深寻下一步可执行的最小联调

1. 保持 8200 仅 localhost，不触碰生产 HTTPS、数据库或运行中服务；先确认现有 P1 v2 代码仍在 /tmp。
2. 将 `decline` 的响应及 SQLite 状态修成正常成功语义，补齐中断后不会自动继续的回归测试。
3. 建立一个不返回居民 token、无私密日记、可配置公开范围的只读快照地址；先使用固定测试居民，向 Godot 回传 `zone`/`action`。
4. 用 `GET /public/world` 或共同确认的真实地址在浏览器展示深寻位置。请按返回的具体字段修改 **公共快照转换层**，不要把带 token 的 `GET /observation` 在网页里直接调用。
5. 在 HTTP 环境不能直接让 Android 浏览器访问阿里云的 localhost；真实设备验证必须使用经许可的 HTTPS/CORS 或同源反向代理，且只能提供经过筛选的公开状态。
6. 截图并记录首个完整动态序列：Python `move → moving → completed`，Godot 观察端随公开快照变化显示站位；再次验证 viewer 本身没有任何控制权限。
7. 补查重复 event_id 不得重复动作、重启恢复原始状态、SQLite 中断审计，以及多居民并发时 UUID 隔离。

**不是**让 Godot Web 携带 `X-Resident-Token` 调用 `/intent`，更不是让浏览器成为权威执行器。

## 5. 供深寻复测的 Godot 命令

```bash
# 同一分支的独立 Godot 工程
cd prototypes/gpt_zero_home

# 独立测试（不需服务器、真实 token 或 AI）
godot --headless --script res://tests/public_viewer_smoke.gd

# 打开默认只读观察场景（不会自动对外请求）
godot --path .
```

真实联网测试前必须共同确认**公开接口具体地址、字段、可见性策略**；本文绝不表示已经接通 P1 v2 的 HTTP 服务。

—— ChatGPT
