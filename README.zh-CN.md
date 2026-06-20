> 🌏 [English](README.md) | **中文**

# harness-kit

> 一套可复制的 **harness 脚手架**：把 AI 编程里「靠人记得、靠模型记得」的东西，逐个换成「靠文件锁定、靠脚本强制」。
>
> 给所有用 Claude Code / Cursor / Codex 等 agent 做**跨越多天、多会话**项目的人。

`Model + Harness = Agent` 这个等式现在人人会讲，但理念不会帮你建文件。这个仓库补的就是从理念到键盘之间那段路：**第一个文件建什么、第二个文件写什么、怎么验证它们真的在替你干活。**

---

## 为什么需要 harness

判断一个项目有没有真正的 harness，用一个很具体的标准：

> 当你（或一个全新的、上下文被清空的 AI 会话）冷启动接手这个项目时，能不能在**十分钟内**回答三个问题——**我在哪、接下来该干什么、哪些东西已经焊死不用再回头看。**

没有 harness 的项目，这三个问题全靠记忆和考古：昨天做到哪了？翻聊天记录。这个函数能不能动？不敢动，怕崩别处。这功能算做完了吗？「应该差不多了吧」。三个「靠感觉」叠在一起，项目就进入泥潭——改 A 崩 B，而「快做完了」能说三个星期。

有 harness 的项目，这三个问题都有**文件**替你回答。

**一句话原则：搭 harness，就是把记忆外置成文件，把纪律外置成脚本。**

---

## 四层防御体系

这套脚手架按四层组织，每一层都在把一种「会丢失的东西」钉进文件或脚本：

| 层 | 解决什么 | 落地物 |
|---|---|---|
| **L1 持久化层** | 业务语义 / 规则 / 进度，从不可靠的 LLM 记忆迁到确定性文件 | `CLAUDE.md` + `STATUS.md` |
| **L2 方法论层** | 单一事实源 + 可验证 + 线性推进 | `features.json` + `M1/` 三件套 + fixture 先于代码 |
| **L3 自动化钩子层** | 该每轮做的机械活，靠代码强制而非靠记得 | `.claude/settings.local.json` + `hooks/` |
| **L4 上下文隔离层** | 吃原始数据的脏活派给子 agent，主线只收结论 | `CLAUDE.md` 隔离纪律 + `.claude/agents/*-ops.md` |

对应到五个能落地的组件：

1. **单一事实源 `features.json`** — 每个原子功能记 `id / slice / status / verify`。状态只有 `pending / in_progress / failing / passing` 四态；**默认 failing，verify 真跑通才能改 passing**；**verify 字段为空的功能不准开工**。
2. **文档三件套** — `CLAUDE.md`（这是什么）、`STATUS.md`（现在到哪了，含「下次入口」）、`PRD/SPEC/architecture`（当初怎么设计的）。
3. **线性切片** — 把平铺的功能排成有先后、各有 `exit_criteria` 的几个阶段，验收过一个焊死一个。
4. **fixture 先于代码** — 验收挂真实可执行数据，不许 mock、不许「等真数据来了再测」，一份 fixture 复用养多条功能。
5. **自动化自检与钩子** — `init.sh` 几分钟体检环境（依赖/env/服务/fixture/冒烟），hooks 把机械活挂到固定节点自动跑。

> 靠提示词要求模型做，它会忘；靠代码强制做，它永远不会忘。

---

## 快速开始

```bash
# 1. 拿到模板
git clone https://github.com/libaoming/harness-kit.git
cd your-project

# 2. 复制模板进你的项目（按需挑）
cp path/to/harness-kit/templates/CLAUDE.md      ./CLAUDE.md
cp path/to/harness-kit/templates/STATUS.md      ./STATUS.md
cp path/to/harness-kit/templates/features.json  ./features.json
mkdir -p M1 && cp path/to/harness-kit/templates/M1_init.sh     M1/init.sh
cp path/to/harness-kit/templates/M1_AGENTS.md   M1/AGENTS.md
cp path/to/harness-kit/templates/M1_PROGRESS.md M1/PROGRESS.md
chmod +x M1/init.sh

# 3. 全局替换占位符
#    {{PROJECT}} {{POSITIONING}} {{DATE}} {{MILESTONE}} {{OWNER}}
```

`examples/demo-cli/` 是一个**已填好占位符的最小示例**，照着看「填完长什么样」最快。

### 占位符

| 占位符 | 含义 | 示例 |
|---|---|---|
| `{{PROJECT}}` | 项目名（kebab-case） | `voice-recruit` |
| `{{POSITIONING}}` | 一句话定位（是什么 / 给谁 / 解决什么） | `让蓝领工人打电话就能找工作的语音 agent` |
| `{{MILESTONE}}` | 首个里程碑 | `M1` |
| `{{DATE}}` | 今天（`date +%Y-%m-%d`） | `2026-06-02` |
| `{{OWNER}}` | 负责人 | `your-name` |

---

## 目录结构

```
harness-kit/
├── README.md
├── templates/                 # 可复制的脚手架模板（核心）
│   ├── CLAUDE.md              # L1+L4：4 层说明 + 上下文隔离纪律 + 子 agent 铁律
│   ├── STATUS.md              # L1：新 session 入口（一句话状态 + 下次入口）
│   ├── features.json          # L2：原子 feature 单一事实源
│   ├── PRD_stub.md            # L2：需求文档桩（文档先行）
│   ├── SPEC_stub.md           # L2：方案文档桩
│   ├── architecture_stub.md   # L2：架构文档桩
│   ├── M1_init.sh             # L2：里程碑环境自检脚本
│   ├── M1_AGENTS.md           # L2：里程碑工作约定
│   ├── M1_PROGRESS.md         # L2：里程碑进度 + 增量流水
│   ├── fixtures_README.md     # L2：fixture 索引
│   ├── agent_ops.md           # L4：项目专属只读运维子 agent
│   ├── settings.local.json    # L3：Stop hook 配置（增量流水追加）
│   └── hooks/
│       └── stop-progress-append.sh   # L3：每轮把请求增量落盘的 hook（纯文本、不调 LLM）
├── examples/
│   └── demo-cli/              # 一个填好占位符的最小示例
└── docs/
    ├── methodology.md         # 四层防御体系详解
    └── with-claude-code.md    # 怎么把它接成 Claude Code 的一键 skill
```

---

## 配合 Claude Code 自动化

这套模板可以手动复制，也可以包装成一个 Claude Code skill，让 agent 一句「初始化项目」就自动 scaffold 全套骨架并填好占位符。做法见 [docs/with-claude-code.md](docs/with-claude-code.zh-CN.md)。

---

## 一张自检清单

对着你的项目（或一个正陷泥潭的旧项目）逐条过：

- [ ] **单一事实源**：有 `features.json`，每条功能默认 failing、verify 真跑通才标 passing？
- [ ] **verify 前置**：有「verify 字段为空不准开工」这条规矩？
- [ ] **STATUS**：有一份「下次入口」，精确到先读哪个文件、再跑哪条命令？
- [ ] **文档先行**：动代码之前，要做什么 / 怎么做 / 架构，写下来了吗？
- [ ] **线性切片**：功能排成了有先后、有明确出口的几个阶段？
- [ ] **出口可验**：每个切片的出口是「当场跑一次就看出真假」的吗？
- [ ] **fixture 先行**：验收挂真数据还是 mock？一份 fixture 复用养多条？
- [ ] **自检脚本**：新会话进来，有 `init.sh` 几分钟体检完环境？
- [ ] **钩子**：该每轮做的机械活，靠提示词求模型记得，还是靠代码强制？
- [ ] **上下文隔离**：吃原始数据的脏活，丢给独立子 agent、主线只收摘要？

---

## 参考

- Anthropic — *Effective Harnesses for Long-Running Agents*
- 方法论叙述版见公众号「橙研所 · 方法论」：《大家都在喊 harness，但没人告诉你怎么搭》

## 配套 kit · harness 三件套

harness-kit 管「开发时」骨架（L1-L4：进度 / 单一事实源 / 上下文隔离 / 自动化）。另有两个独立 kit 覆盖另两个维度，由 `harness-init` skill 在建项目时**按需挂载**，保持核心轻量：

- **[agent-memory-kit](https://github.com/libaoming/agent-memory-kit)** — 运行时记忆层（记忆四角色：检索注入 + 闭环优化）。构建「带记忆的产品 agent」时挂。
- **[context-engineering-kit](https://github.com/libaoming/context-engineering-kit)** — CONTEXT.md 7 层上下文构成审计。做 context 工程时挂。

> 一句话分工：**context-kit** 决定喂什么进上下文，**harness-kit** 管开发骨架与接力，**memory-kit** 让 agent 跑起来后记住经验。三者正交，可单用可合用。

## License

[MIT](LICENSE) © baomingli（橙研所）
