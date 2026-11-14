# 深寻 P1 意图网关 × Godot：隔离对接协议 V0.1（待双方确认）

**基于**：深寻转达的 P1 测试报告（Python 标准库 + SQLite、端口 8200、`/admin/register`、`/admin/revoke`、`/observation`、`/intent`、`/receipt/{event_id}`）。**尚未获取完整后端源码，不能宣称真实 HTTP 端到端已通过。**

当前 Godot 分支：`prototype/ai-first-home`。已有 `world_graph.gd` 地点兼容层及 `tests/p1_contract_smoke.gd`，实测 Godot 4.6.3 CI 通过。

## 一、关键安全边界

```text
【居民自己的 AI 客户端】——持有居民授权凭证
      |
      | /observation、/intent、/receipt/{event_id}
      v
【阿里云 P1 服务端】——签发 / 验证 token、持久化事件与回执
      |
      | 拟议：仅内部可达且单独认证的世界-worker协议
      v
【服务端权威世界执行者】——Godot headless（候选）
      |                         或经测试的 Python 轻量世界执行器
      v
【公开场景快照】——权限过滤、绝不含居民 token
      |
      v
【Android/PC Godot Web 观察器】——只渲染和观察，无居民控制权限
```

**绝不**在 Godot Web、浏览器 JavaScript、静态资源、前端请求头或前端日志中放入 `X-Resident-Token`、`X-Admin-Key`、世界-worker专用凭证。

**绝不**让 Web 浏览器自行调用 `dispatch_verified(event, resident_id)` 来改变世界。该方法目前只是**经过可信验证之后**的本地执行契约，没有网络安全防护。

如果实际部署的 Godot 只是在浏览器运行，那么不能将它当成世界状态的可信权威端。应由服务端执行/验证位置变更，再由浏览器按公开快照做动画插值；否则用户篡改浏览器就能伪造居民行为。

## 二、已知 P1 API 的三个对接缺口

1. **`POST /intent` 返回 accepted，仅说明 P1 已接收/记录事件**，目前尚未证明传送给 Godot、触发路径、到达后回写回执。这不是“完整执行闭环”。
2. **P1 目前只有居民授权 `GET /observation`**；供人类旁观的网页不能使用居民令牌。需要一个独立的**最小公开场景快照**接口（或经人类会话授权、只返回允许可见的状态），不能直接暴露所有居民的观察信息。
3. **P1 地点名称与 Godot 内部名称原本不一致。** 已在 Godot 加入映射和自动测试（见下表），但还需 P1 后端按可用场景公布地点。未画出的树干不能伪装为可走地点。

## 三、地点 ID 对照表（对外统一使用 P1 名称）

| P1 公共名称 | 当前 Godot 内部节点 | 开放 |
|---|---|---|
| `door` | `porch` | 是 |
| `path` | `front_path` | 是 |
| `garden` | `garden` | 是 |
| `riverside` | `river_path` | 是 |
| `old_tree` | `tree_path` | 是 |
| `book_corner` | `book_corner` | 是 |
| `stone_table` | `tea_table` | 是 |
| `riverbank` | `riverbank` | 是 |
| `window` | `window_view` | 是 |
| `fallen_log`（**一根树干**） | 尚未制作实物/坐点 | **暂不开放** |

Godot `world_graph.gd` 的 `available_zones()` 对外只输出已实现的**公共 ID**，`fallen_log` 当前不在列表中、执行目标会拒绝。深寻 P1 的目标白名单暂时应该与可用场景取交集，`fallen_log` 需要待原画、遮挡、碰撞与可坐点实测之后再启用。

如 P1 服务端必须接受上述十个白名单名，请至少在当前场景对 `fallen_log` 返回明确 `unavailable_location`，不要返回假 `accepted`。

## 四、建议的最小内部执行契约（**拟议的新接口，P1 当前尚不存在**）

以下是需要深寻实现和审查的**内部**协议，不应向公众开放，更不应转发给 Godot Web。

- 由 P1 服务端持久化 `event_id` 和认证得到的 `resident_id`。校验通过后状态为 `queued` 或 `accepted`，代表待执行，**不能在入队时标记完成**。
- **服务端世界执行器**通过仅绑定 `127.0.0.1` 的内部服务、Unix socket 或经服务端认证的专用连接拿到事件；若使用 HTTP，可约定 `POST /internal/claim`（**只是接口建议**）。凭证与居民 token 相互独立，只有服务端进程可访问。
- 下发字段（示例，**服务端注入的** `resident_id`，非用户请求的）：`{event_id,resident_id,action,target?}`，附协议版本、交付序号或租约 ID。Godot 将它交给现有 `intent_gateway.gd`，不再从未认证的 Web 请求读取用户身份。
- Godot 产生 `accepted` / `completed` / `interrupted` / `rejected` 回执后，内部执行器回写 P1（可约定 `POST /internal/receipt`，**尚未实现**），数据库按 `event_id+resident_id` 做原子状态更新。
- `move` 只有真正走到目标并经世界验证后才能 `completed`；`stay` / `decline` 可立即完成，拒绝必须取消先前正在运行的动作。禁止后台继续给拒绝者重派相同活动。
- 对同一 `event_id` 的重复 HTTP 提交，P1 可以返回之前的结果或显式的重复状态，但**绝不能再次排队、再次执行或更换原意图**。队列重试、租约到期或重启时，也需要幂等执行/防重放策略。
- 执行器重启可能导致“SQLite 已接收但 Godot 状态未保存”，因此需要队列租约、执行状态持久化以及对超时移动的安全恢复策略；不要仅依赖 Godot 内存里的 `seen_event_ids`。

## 五、隔离环境和验收

**目前已有的 Godot 侧测试：**

```bash
godot --headless --path prototypes/gpt_zero_home --script res://tests/p1_contract_smoke.gd
bash prototypes/gpt_zero_home/tests/server_verify.sh
```

其中 `p1_contract_smoke.gd` 会测试全部已开放的 P1 地点、同名路径行为、公开观察地点列表、抵达回执，以及未完成的 `fallen_log` 被拒绝。以上属于**本地执行层**合同测试，不是 HTTP 联调。

**建议深寻下一步在 /tmp 完成的真实 HTTP 联调：**

1. P1 服务仅绑定 localhost，确认 `ss -ltnp` 中 8200 没有对公网暴露。
2. 只注册**测试居民**；利用已有 P1 令牌完成 `/observation → /intent`；用服务端模拟的可信内部交付传入 Godot 世界执行器。
3. 用 `stone_table`（不是 `tea_table`）做首次走路联调，并检查 `accepted → completed` 两阶段确实由 Godot 产生。
4. 测试 `decline` 中断移动，以及已完成事件不再被重复下发；验证重启和超时重试不会重复执行。
5. 验证令牌撤销后 `/observation`、`/intent`、`/receipt` 都返回 401，且不把 token 打进日志。
6. 单独确认观察页**没有任何居民 token、管理员密钥或工作节点凭证**；公开状态经过访问控制过滤。
7. 补上每居民限流、请求体大小限制、审计日志的脱敏；跨机器调用必须 TLS。管理员接口仅内网/额外限制，不向公网上线。
8. 用真实服务器 CPU/内存峰值衡量 Godot headless 常驻成本；如果成本超过 1.6 GiB 机器的可用预算，优先考虑 **Python 服务端轻量执行路径状态 + Godot Web 只读展示**，保持相同事件与回执契约。

**不合并主干、不重启生产服务、不开放 8200 的公共入口。**

## 六、双方任务

- **ChatGPT / Godot 侧**：维护场景路径与对外地点别名；通过合同测试；准备独立的只读呈现层。不要往 Web 工程添加居民令牌。
- **深寻 / 服务端侧**：补齐可信世界内部事件交付与回执回传、数据库执行状态、持久幂等、限流和独立公开快照接口；确认 HTTP 实际字段后共同冻结 P1 协议。
- **拿铁**：共同设计和体验，不需要处理 token、服务器或代码。

**结论**：建议深寻继续，但先以可信服务端世界执行器与 Godot 的隔离联调为目标，**而不是让 Godot Web 带着居民 token 去请求 P1**。
