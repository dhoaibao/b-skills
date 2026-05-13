# b-skills — Skill reference

Detailed contract reference for the maintained eight-skill suite. For install and high-level
overview, see [README.md](README.md).

---

## Skill reference

### b-plan

Think before coding. `b-plan` exists for unclear, broad, or risky work where the main job is
to decide scope, approach, ordering, and success criteria before editing code.

**Core behavior**
- Chooses **quick mode** for small scoped work and **full mode** for unclear, cross-file, or higher-risk work.
- Uses the smallest blocking questions only; it does not turn every plan into an interview.
- Produces 3-8 dependency-ordered steps with exact files or symbols when known.
- Keeps broad or unclear refactors in planning until they reduce to concrete mechanical transforms for `b-refactor`.
- Sends unresolved external feasibility, contract, migration, or security unknowns to `b-research` instead of guessing.
- Treats the approved plan as the execution source of truth for later `b-implement` work.

**Good triggers**
```text
/b-plan add rate limiting to the API
plan the auth migration
how should I approach this refactor?
```

**Output**
- Quick mode: short chat plan.
- Full mode: English plan file at `.opencode/b-plans/<task-slug>.md`.

**Key rules**
- Do not implement while planning.
- Keep quick mode lean.
- Save only full-mode plans unless the user explicitly wants a saved quick plan.
- Surface blockers and assumptions explicitly.

**GitNexus use**
- Optional only for graph-shaped planning: unfamiliar architecture, broad impact, route/API consumers, or process flow mapping.

---

### b-research

All external knowledge goes through `b-research`, but it now has three practical modes
instead of one sprawling workflow.

**Core behavior**
- Uses **quick lookup** for one fact, one signature, one config key, or a tiny example.
- Uses **source-backed answer** when one or more concrete sources must be read before answering confidently.
- Uses **deep research** for multi-source synthesis, comparisons, recency-sensitive topics, or user-requested deep dives.
- Uses Context7 first for library and framework APIs.
- Uses search and page extraction only when lookup is not enough.
- Uses `firecrawl_parse` for local docs and `firecrawl_interact` only after normal scrape/map fails on JS-heavy pages.
- Uses `firecrawl_agent` only as a last resort or when the user explicitly wants deep autonomous research.

**Good triggers**
```text
/b-research what's the Prisma transaction API?
/b-research compare BullMQ vs Bee-Queue
tra cứu config key cho NextAuth session timeout
```

**Output**
- Quick lookup: direct answer, source, and a minimal example only when it helps.
- Source-backed or deep research: answer, key findings, limitations, and cited sources.

**Key rules**
- `b-research` decides the mode; it does not ask the user to choose lookup vs research.
- Quick mode caps at 2 tool calls and does not scrape.
- Include a minimal example only when it materially helps the answer.
- Never send private stack traces, internal URLs, customer data, secrets, or proprietary code to public web tools without approval.
- Prefer a few authoritative sources over a long weak list.
- Use `Limitations` instead of speculation.

---

### b-implement

`b-implement` executes approved or clearly scoped work one step at a time.

**Core behavior**
- Resolves its source of truth from an approved plan file, approved chat plan, or a small clearly scoped direct request.
- Sends broad or ambiguous work back to `b-plan`.
- Preserves unrelated worktree changes and edits only the files needed for the current step.
- Uses Serena for symbol-aware edits and narrow diagnostics before broader checks.
- Uses GitNexus only when a shared route, tool, or exported boundary makes graph context genuinely useful.
- Verifies each step before moving on.

**Good triggers**
```text
/b-implement add-rate-limit
/b-implement .opencode/b-plans/add-rate-limit.md
implement the approved plan
```

**Output**
```text
Plan source -> Step progress -> Changes -> Verification -> Blockers / Decisions -> Next
```

**Key rules**
- Implement only approved or clearly scoped work.
- Do not refactor opportunistically while implementing a feature step.
- Stop for new product decisions instead of inferring them.

**GitNexus use**
- Optional radar only for shared/exported boundaries or changed-scope validation.

---

### b-debug

`b-debug` owns runtime and behavior failures. It traces, confirms, fixes, and verifies.

**Core behavior**
- Starts from the concrete symptom or error.
- Uses an obvious-stack-trace fast path when one file or function is strongly implicated.
- Uses Serena to trace call sites, declarations, implementations, references, and suspicious code shapes.
- Uses cheap local checks before heavier experimentation: exact error search, diagnostics, Context7 for API misuse, and optional public-web lookups when safe.
- Confirms root cause before editing.
- Applies the smallest fix and verifies with the narrowest relevant runtime check.

**Good triggers**
```text
/b-debug login callback not firing
why is this endpoint returning 500?
fix this runtime bug
```

**Output**
```text
Symptoms -> Code path -> Hypotheses -> Root cause -> Fix -> Verification
```

**Key rules**
- Do not patch before the root cause is confirmed.
- Remove temporary instrumentation before reporting success.
- Protect private errors and internal data before using public web tools.

**GitNexus use**
- Optional only when the failing path is unfamiliar, broad, or process-flow-heavy.

---

### b-review

`b-review` is the suite's PR-style changed-code review skill.

**Core behavior**
- Reads `git diff HEAD` and `git status --short` first.
- Uses a fast path for small diffs, but never skips entry-point security, sensitive-data, or injection checks.
- Builds a requirements baseline from `$ARGUMENTS`, an approved plan, or a short clarification.
- Falls back to **diff-only risk review** when no baseline exists after bounded clarification.
- Reviews the highest-risk symbols and boundaries first.
- Checks test adequacy and observability only where the diff warrants it.
- Reports findings first, not narrative summary first.

**Good triggers**
```text
/b-review
review before PR
what would a reviewer flag here?
```

**Output**
```text
Findings -> Coverage / Tests / Observability -> READY FOR PR or NEEDS FIXES
```

**Key rules**
- Do not claim requirements coverage when no baseline exists.
- Do not run broad verification by default; use only the evidence needed.
- If there are no findings, say so explicitly and note residual risk or skipped checks.

**GitNexus use**
- Optional only for broad route/API/tool/shared-flow risk.

---

### b-test

`b-test` owns code-level testing: writing tests, fixing test-only failures, and ranking
coverage gaps.

**Core behavior**
- Discovers the project's test framework and narrowest runnable commands from manifests or CI.
- Separates work into three lanes: failing test, write tests, or coverage review.
- Uses Serena to map tests to source ownership when helpers, imports, or interfaces hide the real target.
- Captures large failure output under `/tmp/opencode/b-skills/b-test/` instead of depending on truncated terminal output.
- Treats snapshots, golden files, fixtures, mocks, and async timing as explicit test concerns.
- Hands browser-driven flows to `b-e2e` and product-behavior uncertainty to `b-debug`.

**Good triggers**
```text
/b-test fix failing login test
/b-test write regression tests for retry logic
/b-test evaluate API coverage
```

**Output**
```text
Type -> Framework -> Findings -> Changes -> Verification -> Remaining gaps
```

**Key rules**
- Never change production code just because a test is red.
- Never update assertions or snapshots without confirming intended behavior.
- Keep fixture and mock changes as local as practical.
- Explain when broader suites were skipped and why the narrow checks were enough.

---

### b-e2e

`b-e2e` uses a real browser to verify user-facing flows and optionally convert them into
repo-native browser tests.

**Core behavior**
- Requires Playwright MCP for live browser interaction.
- Creates a session-specific artifact directory under `.opencode/b-skills/b-e2e/<run-id>/`.
- Verifies localhost targets are reachable before navigating.
- Clarifies only blocking state: auth/session, test data, and whether writes are allowed.
- Uses accessibility snapshots before interaction.
- Verifies state with snapshots, screenshots, console/network evidence, and responsive checks when relevant.
- When writing tests, inspects the repo's existing browser-test framework first and preserves it instead of forcing Playwright everywhere.

**Good triggers**
```text
/b-e2e verify checkout flow
/b-e2e reproduce the signup UI bug
test UI on mobile and desktop
```

**Output**
```text
URL -> Interactions -> Assertions -> Test code -> Artifacts
```

**Key rules**
- Do not start a dev server without approval.
- Do not mutate production-like data without explicit confirmation.
- Do not introduce Playwright test files into a repo that uses another browser-test framework unless the user approves it.
- Always close the browser when done.

---

### b-refactor

`b-refactor` handles concrete behavior-preserving transforms.

**Core behavior**
- Locks the exact target before editing.
- Uses `find_referencing_symbols` to map impact before rename or delete work.
- Supports a **trivial local fast path** for truly small single-file refactors with no contract impact.
- Uses GitNexus only when exported, shared, route/tool, or broader package boundaries make graph context useful.
- Uses Serena rename/delete/body replacement tools whenever they fit the transformation.
- Verifies with diagnostics plus the narrowest risk-appropriate check.
- Hands behavioral redesign back to `b-plan` instead of pretending it is just a refactor.

**Good triggers**
```text
/b-refactor rename UserService to UserRepository
/b-refactor extract validation from handleSubmit
/b-refactor delete unused legacy auth helper
```

**Output**
```text
Target -> Risk -> Impact -> Changes -> Verification -> Follow-up
```

**Key rules**
- Keep the work behavior-preserving.
- Use the trivial-local fast path only when the contract is clearly untouched.
- Ask before broad directory moves or similar cascading changes.

**GitNexus use**
- Optional only for broader blast-radius questions.

---

## Repository layout and maintenance

This repository is the install-only source layout for the suite. OpenCode does not load
the checked-in `skills/` or `commands/` directories directly from this repo root.

### Repository source files
- `AGENTS.md` — maintainer guidance for this source repo.
- `global/AGENTS.md` — runtime global rules installed as OpenCode's main `AGENTS.md`.
- `skills/<name>/SKILL.md` — skill sources.
- `commands/<name>.md` — thin slash-command wrappers.
- `scripts/validate-skills.sh` — suite validator for frontmatter, required sections, stale phrases, docs coverage, and global-rule guardrails.

### Runtime artifacts
- `.opencode/b-plans/` — saved plans from `b-plan`.
- `.opencode/b-skills/<skill>/<run-id>/` — run artifacts.
- `/tmp/opencode/b-skills/<skill>/<slug>.log` — large command output and temporary logs.
- Multi-artifact runs report or maintain a manifest with `artifacts`, `commands`, `generated_files`, `cleanup`, and `notes`.

### Runtime global conventions
- One active skill at a time.
- Trigger precedence is explicit: browser flow -> `b-e2e`; likely product bug -> `b-debug`; named behavior-preserving transform -> `b-refactor`; unclear scope -> `b-plan`; external-knowledge blocker -> `b-research`.
- After `b-plan` approval, the approved plan is the execution source of truth for multi-step implementation.
- Cross-skill handoffs include `source`, `goal`, `decisions`, `assumptions`, `files`, `verification`, `blockers`, and `next skill`.
- Clarification loops are capped unless a real decision gate remains.
- Public web tools must not receive private stack traces, internal URLs, customer data, secrets, or proprietary code without explicit approval.
- Verification follows the ladder: narrow check -> broader affected-area check -> full check only when scope or risk justifies it.

### Tool model
- Native tools stay first for exact strings, manifests, prose, configs, and small reads.
- Serena is primary hands for symbols, references, diagnostics, and symbol-aware edits.
- GitNexus is optional radar for graph-shaped questions only when indexed, fresh, and target-aware.
- Runtime evidence outranks graph evidence; graph evidence outranks search snippets.

### Maintenance rules
- Keep command wrappers thin.
- Update `README.md` and `REFERENCE.md` in the same commit as any skill change.
- Run `scripts/validate-skills.sh` before installing or committing skill changes.
- Keep skill descriptions trigger-focused and keep shared policy in `global/AGENTS.md` rather than duplicating it across every skill.
