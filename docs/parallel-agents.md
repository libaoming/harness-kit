# 并行编排层（可选 · 多 agent 并行）

> harness-kit 的核心四层（L1–L4）是为**单线接力**打磨的：一个 agent 跨天、跨会话，别迷路、别返工。
> 这一层是它的可选扩展，解决另一个象限的问题：**多个 agent 同一时刻并行干活，怎么不互相踩、怎么汇到一起。**
>
> 像 `agent-memory-kit` / `context-engineering-kit` 一样**按需挂载**——任务真能切成互不依赖的并行块时才用，**默认仍是单线**。

---

## 问题

有些任务天然能切开并行跑：重构 N 个互不依赖的模块、抓 M 个独立数据源、并行实现几个没有先后关系的 feature。单线一个一个来，是在浪费——steipete 那条帖说得直白：

> Codex spawned 8 subagents to refactor my codebase in parallel. Each one works on a separate module, reports back to a shared markdown file. **I review the diffs every 5 minutes.** … The key insight: **you don't prompt one agent, you orchestrate many.**

但并行不是免费的。一旦多个 agent 同时动手，三个新问题立刻冒出来，全是核心四层没覆盖的：

1. **撞车**：两个 agent 同时改同一个文件，互相覆盖。
2. **失联**：A 干到一半发现情况变了，B 不知道，继续跑错方向。
3. **谁验收**：N 份产出汇到一起，谁来 merge？「每个 agent 都说自己做完了」不等于做完了。

---

## 做法：星型并行（不是白板）

多 agent 协作有两种拓扑，选错就掉进协调地狱：

- **白板（网状）**：每个 agent 都能往一块共享空间读写、彼此间接通信。强，但你要管并发写冲突、状态一致性、争用——这是 MiniMax Agent Team 级的重型设计。
- **星型（汇聚）**：agent 之间**不通信**，每个只把状态单向写到一块板，主线（或人 / grader）负责汇总和 merge。

**核心四层里的 L4「主线派子 agent 收结论」本来就是星型**——这一层只是把它从「外包脏活」扩展到「并行干主线任务」。拓扑不变，依然星型：放弃 agent 间的横向实时协作，换来极简——没有并发写冲突、没有状态一致性问题、没有争用焦点。

> 详见 [methodology.md → 多 agent 的两种拓扑](methodology.md#多-agent-的两种拓扑星型汇聚-vs-共享白板)。一句话：**大多数项目星型够用，白板是你确实需要 agent 边干边对齐时才上的重型方案。**

---

## Recipe（四步）

```
切片 ──► worktree 隔离 ──► 各写 BOARD ──► merge gate
(主线)     (每 agent 一个)    (子 agent)     (人 / grader)
```

1. **切片**（主线做）：从 `features.json` 挑出一组**互不依赖**的 feature（`blocking=[]`、不改同一批文件）。有先后依赖的，依然走线性切片，别硬塞进并行。
2. **worktree 隔离**（防撞车）：每个并发 agent 在自己的 git worktree 里干，`git worktree add wt-<feature_id>`。改动天然隔离、merge 前互不可见——这一步替你消掉了「撞车」。
3. **各写 BOARD**（防失联）：每个 agent 把状态写到 [`BOARD.md`](../templates/BOARD.md) 自己的块（认领 / worktree / 产出 / diff 位置 / blocker），**只写不读彼此**。依赖关系写进 blocker，由主线在 merge 时裁决，而不是让 agent 去读对方。
4. **merge gate**（谁验收）：N 路产出过一道汇聚验收门才进主线——**合一个焊一个**，verify 没真跑通的退回 `producing`。沿用 L2「verify 真跑通才 passing」，只是从单 feature 扩展到 N 路汇聚。

---

## 三个角色

| 角色 | 谁来当 | 职责 |
|---|---|---|
| **切片器** | 主线 | 判断任务能不能并行切开、挑出互不依赖的一组、起 worker |
| **worker** | 并发子 agent | 在自己 worktree 干一个 feature、写 BOARD、不与他人通信 |
| **merge gate** | 人 ／ grader 子 agent | 汇聚验收：人工 review，或 grader 初审标红 + 人只看标红 |

> merge gate 是这套的关键，也最容易偷懒。steipete 用人肉每 5 分钟 review；如果你有一个 grader（LLM-as-judge），可以让它做第一道审（fixture 过没过、lint 干不干净），人只复核它标红的——把「人盯 N 路」降成「人看少数异常」。

---

## 🚦 何时用 / 何时别用

**适合并行**
- 子任务**弱依赖、能各自独立完成**：重构 N 个互不依赖模块、抓 M 个独立源、并行写几个无先后的 feature。
- 产出**容易分别验收**：每路有自己的 fixture / 测试。

**别用并行（保持单线）**
- 子任务**强依赖、要边干边对齐**：那是白板场景，星型不够——但先问自己是不是真到了这一步。
- 任务小：改错别字、单个 feature——单 agent 甚至一个脚本更便宜（**多 agent 不是默认选项**）。
- 你还没有 merge gate：没人验收的并行，只会更快地产出一堆没人敢合的 diff。

> 这条克制本身是方法论的一部分。多 agent 是一笔需要用结构（worktree + BOARD + merge gate）来偿还的负债，不是免费的并行加速。**先想清楚怎么汇聚，再决定起几个 agent。**

---

## 参考
- steipete 的 8-subagent 并行重构工作流（X，2026-06）
- MiniMax Agent Team — 共享白板 / Worker↔Verifier 对抗 / *Cost of Consensus*（「无结构的多消耗 2.1–3.4× token 而准确率不升反降」）
- 叙述版见公众号「橙研所 · 方法论」：《拆 MiniMax Agent Team——多 Agent 协调层的六个真问题》
