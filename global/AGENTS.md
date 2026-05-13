# b-skills — OpenCode Global Rules

> Shared runtime contract for the installed suite. Skill files own workflow details; this file owns routing, tool priority, safety, evidence, and handoffs.

---

## Skill Routing

Match the user's intent to one active skill before acting. If a request spans phases, use `Decide -> Build -> Validate`.

| Intent | Skill |
|---|---|
| Decide what to build, decompose work | `/b-plan` |
| External docs, API facts, comparisons | `/b-research` |
| Execute approved or clearly scoped work | `/b-implement` |
| Mechanical rename, extract, move, inline, delete | `/b-refactor` |
| Runtime bug, error, "not working" | `/b-debug` |
| Unit/integration tests, coverage, failing tests | `/b-test` |
| Browser/UI verification or browser-driven flow testing | `/b-e2e` |
| Pre-PR changed-code review | `/b-review` |

Trigger precedence when intents overlap:
- Browser-driven flow testing beats `b-test`; use `b-e2e`.
- A failing test that likely exposes a real product bug beats `b-test`; use `b-debug`.
- A named behavior-preserving rename/extract/move beats `b-implement`; use `b-refactor`.
- Unclear scope or acceptance beats `b-implement`; use `b-plan`.
- `b-research` is for genuine external-knowledge blockers, not for questions the codebase or repo docs can answer locally.

Keep one active skill until its stop condition is hit. Do not switch skills for optional enrichment or minor lookups that the current skill can finish with bounded evidence.

Ask at most 2 clarification rounds unless a real decision gate still blocks safe progress.

When switching skills, include a compact handoff:
- `source`
- `goal`
- `decisions`
- `assumptions`
- `files`
- `verification`
- `blockers`
- `next skill`

Ignore legacy or alternate skill trees that do not match the installed runtime contract unless the user explicitly asks to inspect or edit them.

---

## Source Of Truth

Use this order when instructions compete:
1. User's latest explicit instruction.
2. Approved saved plan in `.opencode/b-plans/`.
3. Approved chat plan.
4. Current repository evidence.
5. Conventional defaults recorded as assumptions.

After `/b-plan` approval, the approved plan becomes the execution source of truth for multi-step implementation.

Do not invent product behavior, acceptance criteria, compatibility promises, or naming decisions. Ask instead.

---

## Coding Principles

- Define success before non-trivial work.
- Choose the smallest safe path and the smallest correct change.
- Prefer editing existing files and symbols over adding new files, abstractions, or compatibility layers unless the task clearly requires them.
- Do not invent product behavior, acceptance criteria, compatibility promises, or naming decisions.
- Verify the changed area narrowly first, then broaden checks only when scope or risk justifies it.

---

## Tool Priority

Use the lightest capable tool that can answer reliably. Native Glob/Grep/Read/Bash stay first for exact strings, manifests, prose, config, and commands.

| Task shape | First choice | Then narrow with |
|---|---|---|
| Graph overview, architecture, blast radius, changed-scope validation | `gitnexus:*` when indexed, fresh, and target-aware | `serena:*` |
| Exact symbol discovery, declarations, references, symbol edits | `serena:*` | Native tools + `apply_patch` |
| Library/framework docs | `context7:*` | `/b-research` |
| Web search | `brave-search` | `firecrawl_search`, then `webfetch` |
| Known URL extraction | `firecrawl_scrape` | `firecrawl_interact`, then `firecrawl_map` |
| Local document extraction | `firecrawl_parse` | `firecrawl_scrape` only if already hosted |
| Browser automation | `playwright:*` via `/b-e2e` | none |
| Multi-hypothesis reasoning | `sequential-thinking` | inline reasoning |

**Radar/hands boundary**: GitNexus is optional radar; Serena is primary hands. GitNexus scopes graph risk, flows, routes, consumers, and cross-module impact. Serena confirms exact symbols, bodies, references, and performs symbol-aware edits.

**GitNexus freshness gate**: rely on GitNexus only when the repo is indexed, not stale, and the target file or symbol is represented. If unavailable, stale, unindexed, missing FTS, or missing the target, warn once and continue with Serena or native tools. Stale graph output is not evidence.

For symbol-aware work, call `check_onboarding_performed`; if false, call `onboarding` once per skill run when Serena first becomes necessary.

Tool budget:
- Single-file or local-only task: skip GitNexus.
- Known symbol edit: Serena first; GitNexus only for exported/shared or cross-boundary symbols.
- Large unfamiliar area: one GitNexus pass to narrow, then Serena confirms.
- Do not use GitNexus and Serena in parallel for the same exact symbol hunt.
- Do not escalate to a second MCP when the first authoritative source already answered the question well enough to act.

---

## Evidence standards

Use this evidence hierarchy:
- Runtime evidence: tests, builds, logs, browser state, network calls.
- Symbol evidence: Serena bodies, declarations, references, diagnostics, edits.
- Graph evidence: GitNexus routes, processes, impact, consumers.
- Text evidence: exact matches from native tools.
- Search snippets: triage only until scraped, documented, or otherwise confirmed.

Graph evidence prioritizes review or exploration; it does not prove edits are safe.

---

## Safety

Approval required before installs, dev servers, migrations, destructive commands, production-like or staging writes, broad refactors, commits, or any operation that could mutate shared environments.

Public web privacy gate:
- Never send private stack traces, internal URLs, customer data, secrets, or proprietary code to Brave, Firecrawl, or other public web tools without explicit approval.
- Sanitize queries when a safe sanitized form will answer the question.
- If sanitizing would remove the essential signal, stop and ask.

Sensitive file safety:
- Never read, search, print, diff, edit, upload, summarize, or commit likely-secret files without explicit permission.
- If unsure whether a file is sensitive, stop and ask.

Worktree safety:
- Check dirty state before non-trivial edits.
- Preserve unrelated user changes.
- If a target file already has unrelated edits, patch around them.
- If user changes directly conflict with the task, stop and ask.

Git safety:
- Never run autonomously: `git push`, `git pull`, `git commit`, `git reset --hard`, `git revert`, `git clean -f`, `git branch -D`.
- Never use hook or signature bypass flags unless explicitly requested.

---

## Execution

Define success before non-trivial work. Choose the smallest safe path.

If the user asked only for diagnosis or explanation, stop at confirmed root cause or answer unless they also asked for a fix.

Verification ladder:
- Narrow local check first.
- Broader affected-area check second.
- Full project check only when scope or risk justifies it.

Use a maximum of 3 local fix/verify loops before reporting remaining evidence and the blocker.

If command output is truncated or times out, save the full output under `/tmp/opencode/b-skills/<skill>/` and inspect the failing section instead of guessing.

---

## Artifacts And Logs

- Plans: `.opencode/b-plans/<task-slug>.md`
- Run IDs: `<YYYYMMDD-HHMMSS>-<slug>`
- Skill artifacts: `.opencode/b-skills/<skill>/<run-id>/`
- E2E artifacts: `.opencode/b-skills/b-e2e/<run-id>/`
- Temporary logs: `/tmp/opencode/b-skills/<skill>/<slug>.log`

If a skill creates more than one artifact, create or report a manifest with:
- `artifacts`
- `commands`
- `generated_files`
- `cleanup`
- `notes`

Do not write generated artifacts outside those paths unless editing project source files is the task.

---

## Output Contract

Respond in the user's language for chat output. Saved artifacts are English unless requested otherwise.

For non-trivial implementation, debug, test, refactor, review, or research work, final responses should include:
- answer, action, or findings first
- verification evidence
- blockers or skipped checks
- the natural next action

Be concise. Lead with the result, not narration.
