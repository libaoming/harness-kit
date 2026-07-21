> 🌏 **English** | [中文](README.zh-CN.md)

# harness-kit

> A reusable **harness scaffold**: take everything in AI coding that "relies on humans remembering, relies on the model remembering," and swap it, piece by piece, for "locked into files, enforced by scripts."
>
> For anyone using Claude Code / Cursor / Codex and other agents to build projects that span **multiple days and multiple sessions**.

Everyone can recite `Model + Harness = Agent` by now, but a slogan won't build your files for you. This repo fills the stretch of road between the idea and the keyboard: **what the first file should be, what goes in the second, and how to verify they're actually doing the work for you.**

---

## Why you need a harness

Whether a project has a real harness comes down to one very concrete test:

> When you (or a brand-new AI session with a wiped context) cold-start and pick this project up, can you answer three questions **within ten minutes** — **where am I, what do I do next, and which things are already welded shut so I never have to revisit them?**

In a project without a harness, all three answers come from memory and archaeology: Where did I leave off yesterday? Go dig through the chat logs. Can I touch this function? Don't dare — might break something elsewhere. Is this feature done? "Probably close enough." Stack those three "by feel" answers together and the project sinks into a swamp — changing A breaks B, and "almost done" can run on for three weeks.

In a project with a harness, all three questions have a **file** answering them for you.

**The principle in one line: building a harness means externalizing memory into files and externalizing discipline into scripts.**

---

## The four-layer defense system

This scaffold is organized into four layers. Each one pins a different "thing that tends to get lost" into a file or a script:

| Layer | What it solves | Artifacts |
|---|---|---|
| **L1 Persistence layer** | Move business semantics / rules / progress off unreliable LLM memory and into deterministic files | `CLAUDE.md` + `STATUS.md` |
| **L2 Methodology layer** | Single source of truth + verifiable + linear progression | `features.json` + the `M1/` trio + fixtures before code |
| **L3 Automation-hook layer** | The mechanical chores that should run every turn — enforced by code, not by memory | `.claude/settings.local.json` + `hooks/` |
| **L4 Context-isolation layer** | Hand the grunt work that chews raw data to a subagent; the main thread only receives conclusions | `CLAUDE.md` isolation discipline + `.claude/agents/*-ops.md` |

These map onto five concrete, deployable components:

1. **Single source of truth `features.json`** — every atomic feature records `id / slice / status / verify`. Status has exactly four states: `pending / in_progress / failing / passing`; **default is failing, and only a real passing verify flips it to passing**; **a feature whose `verify` field is empty is not allowed to start.**
2. **The document trio** — `CLAUDE.md` (what this is), `STATUS.md` (where we are now, including the "next entry point"), and `PRD/SPEC/architecture` (how it was designed in the first place).
3. **Linear slices** — arrange a flat pile of features into a few ordered stages, each with its own `exit_criteria`; pass one and weld it shut before moving on.
4. **Fixtures before code** — verification hangs on real, runnable data: no mocks, no "we'll test once the real data shows up." One fixture, reused, feeds many features.
5. **Automated self-check and hooks** — `init.sh` gives the environment a few-minute checkup (deps / env / services / fixtures / smoke test), and hooks bolt the mechanical chores onto fixed points so they run automatically.

> Ask the model to do something via a prompt and it will forget; enforce it with code and it never will.

---

## Quick start

```bash
# 1. Grab the templates
git clone https://github.com/libaoming/harness-kit.git
cd your-project

# 2. Copy the templates into your project (pick what you need)
cp path/to/harness-kit/templates/CLAUDE.md      ./CLAUDE.md
cp path/to/harness-kit/templates/STATUS.md      ./STATUS.md
cp path/to/harness-kit/templates/features.json  ./features.json
mkdir -p M1 && cp path/to/harness-kit/templates/M1_init.sh     M1/init.sh
cp path/to/harness-kit/templates/M1_AGENTS.md   M1/AGENTS.md
cp path/to/harness-kit/templates/M1_PROGRESS.md M1/PROGRESS.md
chmod +x M1/init.sh

# 3. Replace the placeholders globally
#    {{PROJECT}} {{POSITIONING}} {{DATE}} {{MILESTONE}} {{OWNER}}
```

`examples/demo-cli/` is a **minimal example with the placeholders already filled in** — the fastest way to see "what it looks like once it's done."

### Placeholders

| Placeholder | Meaning | Example |
|---|---|---|
| `{{PROJECT}}` | Project name (kebab-case) | `voice-recruit` |
| `{{POSITIONING}}` | One-line positioning (what it is / for whom / what it solves) | `a voice agent that lets blue-collar workers find jobs just by making a phone call` |
| `{{MILESTONE}}` | The first milestone | `M1` |
| `{{DATE}}` | Today (`date +%Y-%m-%d`) | `2026-06-02` |
| `{{OWNER}}` | Owner | `your-name` |

---

## Directory structure

```
harness-kit/
├── README.md
├── templates/                 # Reusable scaffold templates (the core)
│   ├── CLAUDE.md              # L1+L4: the 4-layer brief + context-isolation discipline + subagent ground rules
│   ├── STATUS.md              # L1: entry point for a new session (one-line status + next entry point)
│   ├── features.json          # L2: single source of truth for atomic features
│   ├── PRD_stub.md            # L2: requirements doc stub (docs first)
│   ├── SPEC_stub.md           # L2: solution doc stub
│   ├── architecture_stub.md   # L2: architecture doc stub
│   ├── M1_init.sh             # L2: milestone environment self-check script
│   ├── M1_AGENTS.md           # L2: milestone working conventions
│   ├── M1_PROGRESS.md         # L2: milestone progress + incremental log
│   ├── fixtures_README.md     # L2: fixture index
│   ├── record-evidence.sh     # L2: verify evidence recorder — agent-browser video/GIF for UI verifies
│   ├── agent_ops.md           # L4: project-specific read-only ops subagent
│   ├── settings.local.json    # L3: Stop hook config (registers the pair below)
│   └── hooks/
│       ├── stop-progress-append.sh   # L3: persists each turn's request increment (plain text, no LLM call)
│       └── stop-verify-claims.py     # L3: anti-fabrication close-out gate — test -f every "created X" claim at Stop, exit 2 if missing
├── examples/
│   └── demo-cli/              # A minimal example with placeholders filled in
└── docs/
    ├── methodology.md         # The four-layer defense system in detail
    └── with-claude-code.md    # How to wire it into a one-command Claude Code skill
```

---

## Automating with Claude Code

These templates can be copied by hand, or wrapped into a Claude Code skill so that a single "initialize the project" from the agent scaffolds the whole skeleton and fills in the placeholders automatically. See [docs/with-claude-code.md](docs/with-claude-code.md) for how.

---

## A self-check checklist

Run down this list against your project (or an old one that's stuck in the swamp):

- [ ] **Single source of truth**: is there a `features.json` where every feature defaults to failing and is only marked passing once verify truly passes?
- [ ] **Verify first**: do you have the rule "an empty verify field means no work allowed to start"?
- [ ] **STATUS**: is there a "next entry point" precise down to which file to read first and which command to run next?
- [ ] **Docs first**: before touching code, are the what-to-do / how-to-do / architecture written down?
- [ ] **Linear slices**: are features arranged into ordered stages with clear exits?
- [ ] **Verifiable exits**: is each slice's exit one you can tell real-or-fake by running it once on the spot?
- [ ] **Fixtures first**: does verification hang on real data or mocks? Is one fixture reused to feed many features?
- [ ] **Self-check script**: when a new session comes in, is there an `init.sh` that checks the environment out in a few minutes?
- [ ] **Hooks**: the mechanical chores that should run every turn — do you beg the model to remember via a prompt, or enforce them with code?
- [ ] **Context isolation**: the grunt work that chews raw data — is it handed to an isolated subagent so the main thread only gets a summary?

---

## References

- Anthropic — *Effective Harnesses for Long-Running Agents*
- A narrative version of the methodology (in Chinese) on the "橙研所 · 方法论" public account: *"Everyone's shouting harness, but nobody tells you how to build one"*

## Companion kits · the harness trio

harness-kit owns the **dev-time** skeleton (L1–L4: progress / single source of truth / context isolation / automation). Two separate kits cover the other two dimensions, mounted **on demand** by the `harness-init` skill when a project is created, keeping the core lightweight:

- **[agent-memory-kit](https://github.com/libaoming/agent-memory-kit)** — the runtime memory layer (four memory roles: retrieval injection + closed-loop optimization). Mount it when building a "product agent with memory."
- **[context-engineering-kit](https://github.com/libaoming/context-engineering-kit)** — a CONTEXT.md 7-layer context-composition audit. Mount it when doing context engineering.

> The division of labor in one line: **context-kit** decides what gets fed into the context, **harness-kit** owns the dev skeleton and the hand-off, **memory-kit** lets the agent remember its lessons once it's running. The three are orthogonal — use one, or combine them.

## License

[MIT](LICENSE) © baomingli (橙研所)
