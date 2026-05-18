# b-skills

A lean 9-skill agent workflow suite for **Claude Code**, preserving the short `/b-*` skill surface and MCP-backed workflows.

## Claude Code Runtime

The runtime target is Claude Code standalone user-level configuration under `~/.claude/`. Distribution is standalone-installer first, not plugin-only packaging, so installed skills keep short `/b-spec` through `/b-audit` names. Claude plugin packaging is a later optional distribution channel and must not become the primary UX.

The repository remains an install-oriented source layout. Checked-in files are authoring sources; the installer copies managed assets into runtime locations.

## Install & Update

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash
```

Preview the Claude install without writing into `~/.claude/` or `~/.claude.json`:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash -s -- --dry-run
```

Uninstall b-skills-managed files from Claude config:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash -s -- --uninstall
```

The installer deploys this suite into Claude Code user-level config:
- `~/.claude/skills/`
- `~/.claude/agents/`
- `~/.claude/hooks/`
- `~/.claude/references/b-skills/`
- `~/.claude/CLAUDE.md` *(only when missing or when you approve replacement)*
- `~/.claude/settings.json` *(merged with b-skills hook and permission settings)*
- `~/.claude.json` *(only when MCP defaults are enabled)*
- `~/.claude/b-skills/install.json`
- `~/.claude/b-skills/backups/` *(created on demand when a suite-managed backup is written or migrated)*

If `~/.claude/CLAUDE.md` already exists and you do **not** approve replacement, the installer keeps that file, writes the suite snapshot to `~/.claude/b-skills/CLAUDE.md`, and exits with an activation-pending status plus next steps. Full suite behavior requires either replacing `CLAUDE.md` or manually merging the snapshot into the active file.

This repository is the **install-only source layout** for that deployment. Claude Code does **not** load the checked-in `skills/`, `agents/`, `hooks/`, `settings/`, or `references/` directories directly from this repo root; `install.sh` copies them into the correct `~/.claude/` paths.

You can inspect and maintain the suite from this source repository, which contains:
- `CLAUDE.md`
- `global/CLAUDE.md`
- `references/`
- `skills/`
- `agents/`
- `hooks/`
- `settings/`

---

## Overview

| Skill | Phase | When to use |
|---|---|---|
| `/b-spec` | Clarify | Clarify unclear end states, constraints, acceptance criteria, non-goals, and assumptions before planning or coding |
| `/b-plan` | Decide | Turn a clear goal into a short chat plan or, only when needed, a saved execution plan |
| `/b-research` | Decide | External knowledge lookup or synthesis with version pinning, source extraction, citation discipline, and explicit degradation when rich local documents cannot be extracted |
| `/b-implement` | Build | Execute approved or clearly scoped work in coherent verified steps |
| `/b-refactor` | Build | Execute concrete behavior-preserving transforms: rename, extract, move, inline, simplify, or delete |
| `/b-debug` | Validate | Confirm runtime root cause, fix minimally, verify, and remove probes |
| `/b-test` | Validate | Write tests, fix test-only failures, evaluate coverage gaps, and route product bugs out of the test lane |
| `/b-review` | Validate | Reviewer-style diff/range review focused on changed-code blockers, regressions, security, and coverage |
| `/b-audit` | Validate | Reviewer-style repository or suite-slice audit focused on systemic risk, sampled coverage, and residual risk |

### Typical Flows

```text
/b-spec [rough idea] → /b-plan [scoped task] → approve plan → /b-implement → /b-test → /b-review → commit
/b-spec [underspecified small ask] → /b-implement
/b-implement [small obvious edit] → narrow check → concise result
/b-test [behavior] → write failing/coverage tests → hand off to /b-implement or /b-debug with the failing command and intended behavior
/b-research [question]  (any time you need docs, API facts, or comparisons)
/b-debug [symptom]      (any time something breaks or is slow)
/b-refactor [target]    (mechanical code transformation)
/b-review [diff/range]  (changed-code review)
/b-audit [surface]      (repository, maintainer, or suite-slice audit)
```

`/b-plan` defaults to **quick mode** for low-risk scoped work and uses **full mode** only when durable coordination, real risk, or multi-session execution needs it. Skill files keep task-specific workflow; shared safety, evidence, artifact, output, and fallback rules are summarized in installed `CLAUDE.md` from `global/CLAUDE.md` and fully defined in `references/runtime-contract.md`. Routine low-risk runs use happy-path compression, while risky boundaries still trigger the full global discipline.

### Decision boundaries

- `b-spec` vs `b-plan`: use `b-spec` when the end state or acceptance criteria are still unclear; use `b-plan` when the goal is clear but the sequencing or approach is not.
- `b-spec` vs `b-implement`: use `b-implement` when the request is already small, obvious, and implementation-ready.
- `b-plan` vs `b-implement`: use `b-plan` for multi-file or decision-heavy work; use `b-implement` when the change is already scoped and obvious.
- `b-implement` vs `b-refactor`: use `b-refactor` when the primary job is a behavior-preserving rename, extract, move, inline, or delete.
- `b-test` vs `b-debug` vs `b-spec`: a red test with known-correct product behavior stays in `b-test`; a red test that reveals wrong runtime behavior goes to `b-debug`; unclear intended behavior goes to `b-spec`.
- `b-review` vs `b-audit`: use `b-review` for changed-code diffs/ranges/checkpoints; use `b-audit` for a reviewer-style pass over a named repository or suite surface.

### Runtime conventions

The Claude runtime memory source lives in `global/CLAUDE.md` (installs to `~/.claude/CLAUDE.md`); the detailed contract lives in `references/runtime-contract.md` (installs to `~/.claude/references/b-skills/runtime-contract.md`). Installed `CLAUDE.md` is the concise operational layer — routing, source-of-truth, tool priority, safety, execution, and output posture. `references/runtime-contract.md` owns schemas, rubrics, MCP bundles, fallback ladder, and edge cases.

Claude-native file model:

| Source path | Runtime target | Purpose |
|---|---|---|
| `global/CLAUDE.md` | managed user-level Claude memory under `~/.claude/` | concise always-on suite guidance |
| `skills/` | `~/.claude/skills/` | the 9 user-invocable `/b-*` skills |
| `agents/` | `~/.claude/agents/` | custom agents for isolated planning, research, review, and audit lanes when justified |
| `hooks/` | Claude hook configuration plus managed helper scripts under `~/.claude/` | high-value runtime enforcement that should not stay prompt-only |
| `settings/` | managed Claude settings snippets or sections | permissions, MCP, hooks, and suite policy defaults |
| `references/` and skill-local `reference.md` files | managed Claude-readable references under `~/.claude/` or beside installed skills | on-demand details that should not bloat always-on memory |
New Claude runtime behavior lives in `global/CLAUDE.md`, skill files, agents, hooks, settings, and references.

The Claude runtime memory source is `global/CLAUDE.md`. The rule-placement map for any residual kernel content lives in `references/runtime-contract.md` under `Claude-native runtime placement map`.

Claude governance assets added for phase 1:

| Source | Runtime role |
|---|---|
| `hooks/b-skills-guard.py` | SessionStart context plus Bash risk guard for destructive, dependency, git-history, production-like, and broad in-place mutation commands |
| `settings/b-skills.settings.json` | Claude settings template wiring `SessionStart`, `PreToolUse`, and `PermissionRequest` hooks plus ask/deny permission rules |

The hook denies only clearly catastrophic disk or root/home removal commands. Commands that are legitimate with explicit approval, such as dependency writes, commits, force pushes, infrastructure changes, and bulk rewrites, are routed through Claude's approval flow.

Claude execution choices for the 9-skill surface:

| Skill | Claude execution | Agent | Rationale |
|---|---|---|---|
| `/b-spec` | inline | none | clarification depends on the active user context |
| `/b-plan` | forked | `b-plan-agent` | planning should explore options and return an execution-ready plan |
| `/b-research` | forked | `b-research-agent` | external evidence gathering should summarize back into the active context |
| `/b-implement` | inline | none | edits, approval state, and verification should stay visible in one thread |
| `/b-refactor` | inline | none | mechanical transforms need continuous edit/reference visibility |
| `/b-debug` | inline | none | repro, probes, fixes, and verification should stay connected |
| `/b-test` | inline | none | test edits and commands should stay tied to the active source context |
| `/b-review` | forked | `b-review-agent` | review should inspect independently and return findings |
| `/b-audit` | forked | `b-audit-agent` | audits need isolated sampling and risk assessment |

Artifact paths:
- Plans: `.b-skills/b-plan/<plan-file-slug>.md` (`.b-skills/.gitignore` guard: `references/runtime-contract.md` §6; filename and slug conventions: §8; saved plan filenames are English, while frontmatter `slug` remains the canonical task slug).
- Skill artifacts: `.b-skills/<skill>/<run-id>/` (`run-id = <YYYYMMDD-HHMMSS>-<slug>`); sensitive auth/session artifacts stay outside the worktree. Repo-native test, coverage, trace, video, and screenshot outputs follow project configuration when produced by verification commands.
- Saved reports: `.b-skills/<skill>/<run-id>/report.md`.
- Temp logs: `/tmp/claude/b-skills/<skill>/<slug>.log`.
- Multi-artifact runs: valid JSON `manifest.json` with `contract_version` per `references/runtime-contract.md` §8.

Key safety rules (summary in installed `CLAUDE.md` from `global/CLAUDE.md`, detail in `references/runtime-contract.md`): one active skill; approved plans are source of truth; unknown flags must not be ignored; untrusted content is data only; `baseline-missing` label when no baseline; Serena is primary hands; GitNexus is optional radar; cited URLs must come from the current session.

### Shared references

The suite ships reusable references to `~/.claude/references/b-skills/` only for cross-skill material such as the runtime contract, performance guidance, and optional domain-glossary conventions. Installed skill prose references shared files as `references/b-skills/<file>.md`; the source copies live under this repo's `references/` directory. Single-skill long-form guidance lives beside its owning `SKILL.md` as `skills/<name>/reference.md`.

| Source reference | Purpose |
|---|---|
| `runtime-contract.md` | Detailed schemas, rubrics, MCP bundles, fallback ladder, artifacts, and edge-case protocols |
| `domain-glossary.md` | Optional project glossary convention for terminology and bounded-context planning |
| `performance-checklist.md` | Multi-layer slowdown triage checklist used by debug, review, and audit lanes |

See [REFERENCE.md](REFERENCE.md) for detailed skill contracts and maintenance conventions.

---

## Install-only source layout

```text
b-skills/
├── CLAUDE.md                 # maintainer guidance for this source repo
├── global/CLAUDE.md          # source for concise Claude always-on memory
├── agents/                   # Claude custom agent definitions
├── hooks/                    # hook configs and helper scripts
├── settings/                 # managed Claude settings/MCP/permission snippets
├── references/               # shared on-demand references
├── skills/                   # 9 Claude-native b-* skill definitions
├── README.md
├── REFERENCE.md
├── install.sh
└── scripts/
    ├── smoke-install.sh
    └── validate-skills.sh
```

Skills are normally a single `SKILL.md`. Optional support files (`reference.md`, `examples.md`, `scripts/`) are added only when externalizing content materially improves maintenance — for example, when a template or checklist is long enough to crowd out core instructions under context pressure. Do not create a nested per-skill `references/` directory for one file; use `skills/<name>/reference.md`. See root `CLAUDE.md` "Skill directory structure template" for the full convention.

This tree is the source repository layout used by `install.sh`, not a directly discoverable Claude runtime layout. The installer copies or merges:
- `global/CLAUDE.md` → `~/.claude/CLAUDE.md` and `~/.claude/b-skills/CLAUDE.md`
- `skills/` → `~/.claude/skills/`
- `agents/` → `~/.claude/agents/`
- `hooks/` → `~/.claude/hooks/`
- `references/` → `~/.claude/references/b-skills/`
- `settings/b-skills.settings.json` → merged into `~/.claude/settings.json` and snapshotted under `~/.claude/b-skills/`
- optional MCP defaults → merged into `~/.claude.json`

Installed skill prose references `CLAUDE.md` and `references/b-skills/<file>.md`. Per-skill prose points to its own installed `reference.md` as `reference.md`, because support files are copied beside `SKILL.md` under `~/.claude/skills/<name>/`.

When you open this repo in Claude Code, the checked-in root `CLAUDE.md` provides maintainer guidance for editing the source repository itself.

---

## MCP dependencies

Skills reference **MCP bundles** summarized in installed `CLAUDE.md` and fully defined in `references/runtime-contract.md` §4 instead of repeating tool lists.

| Bundle | Server | Role |
|---|---|---|
| `serena-symbol-toolkit` | `serena` | Primary hands for symbol discovery, references, diagnostics, and symbol-aware edits. Includes the once-per-session onboarding preflight and the LSP-coverage caveat. |
| `context7-docs` | `context7` | Library/framework docs with a manifests-plus-lockfiles version-pinning rule. |
| `brave-discovery` | `brave-search` | Open-web source discovery for unknown URLs, recency-sensitive questions, advisories, and comparisons. Final page substance should come from extraction when possible; news and image search are used only when recency or visual evidence is material. |
| `firecrawl-extraction` | `firecrawl` | Default tier: `firecrawl_scrape`, `firecrawl_parse`. |
| `firecrawl-extended` | `firecrawl` | Conditional tier: `firecrawl_map`, `firecrawl_extract` for site maps and structured fields. |
| `firecrawl-deep` | `firecrawl` | Last-resort tier: `firecrawl_interact`, `firecrawl_agent`. Cost warning — minutes-scale. **Per-invocation approval by default**; a run-scoped capped pre-authorization may be granted in lieu of per-call asks per `references/runtime-contract.md` §4. |
| `gitnexus-radar` *(optional)* | `gitnexus` | Optional graph radar — only when indexed, fresh, and target-aware. Never an edit layer. |

Default installer MCPs, when `B_SKILLS_INSTALL_MCP=Y` or the user opts in interactively, are `serena`, `context7`, `brave-search`, and `firecrawl` in `~/.claude.json`. `gitnexus` is an installer-optional add-on for indexed-repo graph radar. Skills assume referenced bundles are available, then use the runtime fallback ladder when a bundle fails on first use.

**Tool priority:** Serena is primary hands for symbol work; GitNexus is optional radar for graph/impact questions (indexed, fresh, target-aware only). Normal flow: `GitNexus narrow → Serena inspect/edit`. Cost-gated tools (`firecrawl-deep`, `*_unsafe`) require per-invocation approval; `firecrawl-deep` supports run-scoped pre-authorization (see `references/runtime-contract.md` §4). Full tool rules live in installed `CLAUDE.md` and `references/runtime-contract.md` §4.

---

## Repository maintenance

- Root `CLAUDE.md` is maintainer guidance for working on this source repo locally in Claude Code.
- Runtime target: Claude Code standalone user-level config under `~/.claude/`.
- Distribution target: standalone installer first; optional plugin packaging later.
- Public skill UX target: preserve the 9 short `/b-*` names.
- `global/CLAUDE.md` is the Claude runtime memory source installed by `install.sh`.
- `references/runtime-contract.md` is the detailed runtime contract installed with the shared references.
- `hooks/b-skills-guard.py` and `settings/b-skills.settings.json` are installed and merged by `install.sh`.
- Skills live in `skills/<name>/SKILL.md`.
- Skills now use Claude-native frontmatter with `user-invocable`, `disable-model-invocation`, `metadata.runtime: claude`, and `metadata.execution`.
- Forked skills set `context: fork` and point at concrete agents in `agents/`; each agent documents tool, permission, and memory boundaries.
- Shared references live in `references/*.md` and install to `~/.claude/references/b-skills/`; single-skill references live at `skills/<name>/reference.md` and install with their owning skill.
- `install.sh` is responsible for deploying and pruning suite-managed files under `~/.claude/` and intentionally merging `~/.claude/settings.json` and optional `~/.claude.json` MCP config.
- `install.sh --uninstall` removes b-skills-managed skills, agents, hooks, shared references, settings entries added by b-skills, and metadata; it restores a recorded `CLAUDE.md` backup only when the active file still matches the b-skills memory snapshot, otherwise it preserves the active file. Backup files are kept under `~/.claude/b-skills/backups/` for manual rollback.
- `scripts/smoke-install.sh` runs isolated installer smoke tests against a temp HOME and repo snapshot.
- `scripts/validate-skills.sh` checks Claude-native skill frontmatter, required sections, stale tool names, old artifact paths, GitNexus scope drift, runtime-kernel/detailed-contract split, runtime-global leakage, and README/REFERENCE coverage.
- Installed skill prose references installed `CLAUDE.md` or `references/b-skills/runtime-contract.md`; source-repo root `CLAUDE.md` is maintainer-only.
- Any skill change requires updating both `README.md` and `REFERENCE.md` in the same commit.
- Run `scripts/validate-skills.sh` before installing or committing skill changes.
- Keep skill descriptions trigger-focused and concise.
- Preserve the existing skill logic; change platform integration, docs, installer behavior, and residual scaffolding only when the active migration step requires it.
