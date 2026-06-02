# 配合 Claude Code 自动化

`templates/` 可以手动复制使用，也可以包装成一个 **Claude Code skill**，让 agent 一句话就自动 scaffold 全套骨架、填好占位符、并按「文档先行」引导你。

## 思路

把这套脚手架做成一个初始化 skill（例如 `harness-init`），作为项目初始化的唯一入口——无论空目录新建，还是给已有代码库补 harness，都走它。

核心流程三步：

### 第 0 步 · 探测目录 + 收集信息

- **空目录 / 不存在** → 走「全新 scaffold」：直接复制模板。
- **已有代码** → 走「纳管」：先做 `/init` 式扫描（读结构、入口、依赖、命令，理解仓库是什么），把扫描结果**填进** `CLAUDE.md` 对应位置，而不是留空壳；已存在的文件先确认再合并，绝不静默覆盖。

收集：项目名（kebab-case）、一句话定位、目标目录、首个里程碑名、是否要项目专属运维子 agent。

### 第 1 步 · scaffold 机械文件

按下表把模板写入目标目录（复制 → 替换占位符 `{{PROJECT}} {{POSITIONING}} {{DATE}} {{MILESTONE}} {{OWNER}}` → 写文件）：

| 模板 | 目标 |
|---|---|
| `templates/CLAUDE.md` | `CLAUDE.md` |
| `templates/STATUS.md` | `STATUS.md` |
| `templates/features.json` | `features.json` |
| `templates/M1_init.sh` | `{MILESTONE}/init.sh`（`chmod +x`） |
| `templates/M1_AGENTS.md` | `{MILESTONE}/AGENTS.md` |
| `templates/M1_PROGRESS.md` | `{MILESTONE}/PROGRESS.md` |
| `templates/fixtures_README.md` | `fixtures/README.md` |
| `templates/agent_ops.md` | `.claude/agents/{PROJECT}-ops.md`（选要才建） |
| `templates/settings.local.json` | `.claude/settings.local.json` |
| `templates/hooks/stop-progress-append.sh` | `.claude/hooks/stop-progress-append.sh`（`chmod +x`） |

### 第 2 步 · 创建文档桩

`PRD / SPEC / architecture` 是项目专属、必须文档先行的，只创建带章节标题的桩（`templates/*_stub.md`），正文留 `> [!TODO]`，提醒先讨论再写。

### 第 3 步 · 报告 + 引导文档先行

输出文件树，并**明确告知：代码还不能开始写**——L2 要求 PRD/SPEC/architecture 文档先行写完才动代码。

## 注意

- 目标目录已有同名文件，**先确认再覆盖**。
- 运维子 agent 默认对远程 / 生产**只读**；项目无远程部署可删掉对应段。
- 不替用户 `git init` / `git push`，除非用户明确要求。
- scaffold 后不要急着写代码——「文档先行」是硬规矩。
