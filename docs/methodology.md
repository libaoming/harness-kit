> 🌏 **English** | [中文](methodology.zh-CN.md)

# The four-layer defense system in detail

The essence of a harness is to take everything that used to "rely on humans remembering, rely on the model remembering" and swap it, piece by piece, for "locked into files, enforced by scripts." The four layers below are each that same move applied along a different dimension.

---

## L1 Persistence layer

**The problem**: every new session, the LLM is completely amnesiac — and a human coming back after a week isn't much better. A project's business semantics, rules, and progress, if they live only in the conversation, evaporate the moment the session ends.

**The approach**: move them into deterministic files.

- `CLAUDE.md` — what the project is, the tech stack, the directory structure, the ground rules, the common commands. The most stable, least-changing "onboarding notice."
- `STATUS.md` — **the soul of the trio**, and the one most people skip. Two parts matter most:
  - One-line status: what stage the project is at today.
  - **Next entry point**: a hand-off guide precise down to "which file to read first, which command to run next, which task to do after that."
- Auto Memory (if your tooling supports it) — long-term preferences and facts that persist across sessions.

**Acceptance**: hand these files to someone who has never touched the project (or a fresh session) and ask them "what should I do now?" If they can answer, it passes.

---

## L2 Methodology layer (development discipline)

**The problem**: "end-to-end is working" is an aggregate metric — it's forever "almost there," and you never know which specific piece is actually welded shut.

**The approach**:

- **Single source of truth `features.json`**: every atomic feature records `id / slice / status / verify`.
  - Four status states: `pending → in_progress → failing → passing`.
  - **Default is failing; only a real passing verify flips it to passing.** A passing unit test only gets you to `in_progress`; only a real end-to-end verify earns `passing`.
- 🚦 **Verifier hard gate**: an empty `verify` field = **no work allowed to start** (it can't leave pending). Every goal must carry a measurable success signal (fixture / test / benchmark / reproducible bug / E2E) — a goal with no verification mechanism is just a wish.
- 🎥 **Recorded evidence (optional, for UI / interaction verifies)**: a verify that touches the interface, an interaction flow, or cross-page state also records a short run video — `./record-evidence.sh start <feature-id> <url>`, run the interaction, then `stop --gif`; the path goes into `verify.evidence`. An exit code only proves the code path finished; it cannot prove what the user actually saw. The recording makes the verify verdict reviewable by a third party without re-running it. Not required for pure CLI / data verifies.
- 🧭 **Three-part linking**: every feature fills in `related / affected / out_of_scope`, so a subagent can instantly judge "which to read, which to skip," curbing context bloat; `out_of_scope` also stops the AI from re-implementing implicit features during integration.
- **Linear slices**: arrange features into a few ordered stages, each with its own `exit_criteria` + `git_tag`; finish one before entering the next.
- **Fixtures before code**: if the fixture referenced by a verify doesn't exist, build it first — no mocks, no "wait for real data." Design a "one fixture feeds many features" reuse structure.
- Put the milestone trio in the `M1/` subdirectory (`init.sh / AGENTS.md / PROGRESS.md`), not the repo root.

---

## L3 Automation-hook layer

**The problem**: the mechanical chores that should run every turn (validation, recording progress, running smoke tests) — ask the model to do them via a prompt and it forgets; rely on a human to remember and the next day's hand-off forgets too.

**The approach**: put deterministic automation in the project-level `.claude/settings.local.json` (local, not committed to git).

This repo ships a built-in **Stop hook** (`hooks/stop-progress-append.sh`): after every turn, it appends "this turn's user request" as plain text to the "incremental log" section of `M1/PROGRESS.md` — no LLM call, survives a power-off, and a crash loses at most the one turn in progress. When a new session starts, merge the incremental log into the formal Session Log before getting to work.

Add others as needed: session-startup injection, artifact sync, pre-commit validation. The principle doesn't change — **anything a deterministic script can do, don't waste the model's (or the human's) attention on.**

---

## L4 Context-isolation layer ⭐

**The problem**: the model's context window is its workbench, and the bench is only so big — pile it full and it gets slow and dumb. Grunt work that chews through large amounts of raw data fills it up fast.

**The approach**: hand the "context-chewing grunt work" to a subagent to run to completion in its own context, and **return only the conclusion**; keep the main context clean and focused on code-change decisions + talking to the user.

**Grunt work that must be isolated** (hand to a subagent, with a fully self-contained prompt):

- Large-document retrieval: PRD / SPEC / a big features.json / long logs → the subagent reads them and returns only "the relevant slice / the answer"; the main context never reads a whole file.
- Remote / production status checks: logs, `systemctl`, container logs (easily thousands of lines) → the subagent returns only the conclusion.
- Large-data / transcript analysis → return only the diagnostic conclusion.

**Keep on the main thread (do not outsource)**: writing code, architecture decisions, talking to the user, verify judgments.

**🚨 Subagent ground rules**:

1. The prompt is **fully self-contained** — hardcode paths, commands, remote aliases (a subagent cold-starts and can't see the main conversation).
2. **Remote / production is read-only** — against anything live, only read-only commands like `systemctl is-active` / `journalctl` / `docker logs` / `grep` / `cat` are allowed.
3. **Changes stay local** — no unauthorized `git push` / `pull` / restarting production / editing production config; deployment is a separate action the user explicitly triggers.

---

## Wrapping it up in one line

Add the four layers together and they're the same judgment applied over and over:

> For this thing — am I relying on remembering, or on files and scripts?

Every place where the answer is "on remembering" is a piece your harness is still missing.
