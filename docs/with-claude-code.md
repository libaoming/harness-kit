> 🌏 **English** | [中文](with-claude-code.zh-CN.md)

# Automating with Claude Code

`templates/` can be copied by hand, or wrapped into a **Claude Code skill** so that a single sentence has the agent auto-scaffold the whole skeleton, fill in the placeholders, and guide you through "docs first."

## The idea

Turn this scaffold into an initialization skill (e.g. `harness-init`) that serves as the single entry point for project initialization — whether you're starting fresh in an empty directory or retrofitting a harness onto an existing codebase, it all goes through this.

The core flow has three steps:

### Step 0 · Probe the directory + collect info

- **Empty / nonexistent directory** → take the "fresh scaffold" path: just copy the templates.
- **Existing code** → take the "retrofit" path: first do a `/init`-style scan (read the structure, entry points, dependencies, commands to understand what the repo is), and **fill that scan into** the right places in `CLAUDE.md` rather than leaving an empty shell; for files that already exist, confirm before merging — never silently overwrite.

Collect: project name (kebab-case), one-line positioning, target directory, first milestone name, whether to include a project-specific ops subagent.

### Step 1 · Scaffold the mechanical files

Write the templates into the target directory per the table below (copy → replace placeholders `{{PROJECT}} {{POSITIONING}} {{DATE}} {{MILESTONE}} {{OWNER}}` → write file):

| Template | Target |
|---|---|
| `templates/CLAUDE.md` | `CLAUDE.md` |
| `templates/STATUS.md` | `STATUS.md` |
| `templates/features.json` | `features.json` |
| `templates/M1_init.sh` | `{MILESTONE}/init.sh` (`chmod +x`) |
| `templates/M1_AGENTS.md` | `{MILESTONE}/AGENTS.md` |
| `templates/M1_PROGRESS.md` | `{MILESTONE}/PROGRESS.md` |
| `templates/fixtures_README.md` | `fixtures/README.md` |
| `templates/agent_ops.md` | `.claude/agents/{PROJECT}-ops.md` (only if requested) |
| `templates/settings.local.json` | `.claude/settings.local.json` |
| `templates/hooks/stop-progress-append.sh` | `.claude/hooks/stop-progress-append.sh` (`chmod +x`) |

### Step 2 · Create the doc stubs

`PRD / SPEC / architecture` are project-specific and must be written docs-first, so only create stubs with section headings (`templates/*_stub.md`), leaving the body as `> [!TODO]` to remind you to discuss before writing.

### Step 3 · Report + guide docs-first

Print the file tree, and **state clearly: code cannot start yet** — L2 requires PRD/SPEC/architecture to be written docs-first before any code is touched.

## Notes

- If a file of the same name already exists in the target directory, **confirm before overwriting**.
- The ops subagent defaults to **read-only** against remote / production; if the project has no remote deployment, delete the corresponding section.
- Don't `git init` / `git push` on the user's behalf unless the user explicitly asks.
- After scaffolding, don't rush into writing code — "docs first" is a hard rule.
