---
name: b-implement
description: >
  Execute approved or scoped work safely. ALWAYS invoke after /b-plan
  approval, when the user asks to execute or implement scoped work, or when a
  small direct request meets the threshold in AGENTS.md §3. Reads the
  approved plan, applies the next small step, verifies it, and stops for new
  decisions. Unlike b-plan, b-implement changes code.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-implement

$ARGUMENTS

Execute approved/scoped work: load source of truth, change the next smallest step, verify, and stop for new decisions.

If `$ARGUMENTS` is present, treat it as the plan path, plan slug, approved chat plan, or **small direct request** as defined in `AGENTS.md` §3.

## When to use

- The user approved a saved plan or chat plan.
- The task is already scoped and the next action is to edit code or docs.
- The request meets the **small direct request** threshold from `AGENTS.md` §3 (≤3 files, no public contract, no sensitive path, no remaining design decision).

## When NOT to use

- The request fails the **small direct request** threshold and is not backed by an approved plan → use **b-plan**.
- The request still has an unclear end state or acceptance criteria → use **b-spec**.
- The request is a named rename, extract, move, inline, or delete → use **b-refactor**.
- The task is only external lookup → use **b-research**.
- The task is only tests → use **b-test**.
- Something is broken and root cause is not confirmed → use **b-debug**.

## Tools required

- `bash` — inspect status, diff, and run verification commands.
- `serena-symbol-toolkit` *(preferred for symbol-aware edits)*
- `gitnexus-radar` *(optional, for shared-route/tool/exported-boundary changes)*
- `context7-docs` *(optional, for a narrow API uncertainty discovered mid-step)*

Fallbacks: `AGENTS.md` §4. If execution reveals a research blocker, stop and use **b-research**. Graceful degradation: ✅ Possible — native tools work, broad symbol changes are riskier without Serena.

## Steps

### Step 1 — Load the source of truth

Resolve scope in this order:
1. A saved plan path under `.opencode/b-skills/b-plan/`.
2. A plan slug under `.opencode/b-skills/b-plan/` (resolved via the slug algorithm in `AGENTS.md` §8).
3. An explicitly approved chat plan.
4. A request that meets the **small direct request** threshold (`AGENTS.md` §3).

If the request fails the threshold and no plan exists, stop and route to **b-plan** via the handoff envelope (`AGENTS.md` §9).

If the request is still ambiguous at the goal level rather than the sequencing level, stop and route to **b-spec**.

Apply the **plan staleness gate** (`AGENTS.md` §2) before executing. A stale plan must be re-planned, not improvised against.

Extract only execution-critical data: approval state, decisions, touch points, steps/request, verification, blockers. If the upstream handoff envelope carried `assumptions`, surface them in the final report and verify any that affect public contracts or sensitive paths before treating them as confirmed.

For saved plans with frontmatter, require `status: approved`, `status: in-progress`, or explicit approval in the current conversation before editing. If approval arrives in chat for a draft plan, update `status`, `approved_at`, `approved_by`, and `approved_head` when available before the first source edit. Legacy plans without frontmatter may execute from explicit current-chat approval per `AGENTS.md` §2.

### Step 2 — Check the working state

Run `git status --short` and inspect only the files relevant to the current step.

- Leave unrelated changes alone (`AGENTS.md` §6 worktree safety).
- If the target file already has unrelated edits, patch around them.
- If user changes directly conflict with the approved scope, stop and ask.
- For non-trivial work, decide before source edits whether execution should stay in the current checkout or move to an isolated workspace/worktree. Prefer isolation when dirty state could interfere, when the task touches a public contract or sensitive path, when parallel work is likely, or when a cleaner review surface materially helps (`AGENTS.md` §6).
- Detect existing isolation first. If the harness already provided it, reuse it; do not create nested isolation.
- If isolation would materially help and none exists, pause and ask before creating or switching to it. If the user declines or the environment blocks it, continue in place and note that choice in the final report.

For implement/finish/continue, proceed through dependency-ready steps while checks pass and no decision appears. For next-step requests, stop after one verified step. Treat small direct tasks as one step.

### Step 3 — Implement the next smallest step

Use `serena-symbol-toolkit` for symbol-aware edits and the cheapest discovery tool that closes the next question (`AGENTS.md` §4). Use `gitnexus-radar` only when the step crosses a shared route, tool, or exported boundary, subject to the freshness gate.

Apply the smallest edit that satisfies the step. For manual `apply_patch` edits, follow the patch discipline in `AGENTS.md` §6.

If the step turns into an unplanned rename, move, extract, inline, or delete → stop and hand off to **b-refactor**.

If a new behavioral or product decision appears → stop and ask.

If the plan itself is wrong (touch points missing, ordering incorrect, decisions invalidated by current code) → trigger the **plan revision protocol** in `AGENTS.md` §2. Do not improvise against the stale plan.

### Step 4 — Verify before moving on

Run the exact plan verification when available. Otherwise run the narrowest relevant check for the touched area, following the verification ladder in `AGENTS.md` §7.

Use `get_diagnostics_for_file` on the touched source file (production code, not just tests) before broader commands when the language supports it. Honor the LSP-coverage caveat in `AGENTS.md` §4.

Classify failures:
- Implementation mistake → fix and rerun.
- `apply_patch` missing expected lines → stale context; re-read the current target slice and retry only with verified smaller context (`AGENTS.md` §6).
- Test harness problem → **b-test**.
- Runtime/root-cause uncertainty → **b-debug**.
- Unresolved library/API behavior → `context7-docs`, then **b-research** if still unclear.
- External (CI down, registry outage, dep yanked) → record the blocker, do not retry inside the iteration cap.

**High-risk challenge gate.** For auth/authz, security boundaries, migrations, public or external contracts, or irreversible external writes, apply the high-risk challenge gate from `AGENTS.md` §10 before calling the step done.

**Documentation-backed decisions.** If framework, library, or vendor API docs determined the chosen pattern, cite the source in the final report. Add a short inline code comment only when the contract would otherwise be non-obvious to a future reader.

**Transform rollback** and **cascading failures** are handled per `AGENTS.md` §7. Surface either explicitly to the user; never exit the skill with the tree mid-transform.

Apply the iteration cap from `AGENTS.md` §7.

### Step 5 — Record progress and finish cleanly

After a step passes verification:
- Update saved-plan checkboxes when present. If the saved plan predates checkbox-style steps, append a short progress note under the completed step instead of rewriting the whole plan format.
- For frontmatter plans, set `status: in-progress` after the first completed step and `status: complete` only when every approved step is done.
- Keep the diff limited to approved scope.
- If the completed step is a coherent high-risk milestone (public/external contract, auth/security/migration boundary, shared route/tool surface, or large user-visible slice), hand off to **b-review** before continuing further unless the plan marks the next work as part of the same tightly coupled verification group. In that handoff, name the exact completed plan step or milestone so review can anchor itself to the intended checkpoint instead of re-deriving it from the diff.
- Continue to the next step only if there is one.

**Step atomicity:** a step is normally an independently-verifiable unit and should pass its own check before the next step begins. The exception is a **tightly coupled group** (e.g., split a function and immediately update its one caller) where intermediate verification would fail by design. The plan must mark such groups explicitly ("Steps 3a–3c verify together"); otherwise treat each step as atomic. Never silently merge atomic steps to dodge a failing check.

At the end:
- Inspect `git diff`.
- Run the final relevant verification.
- State closure explicitly: final verification status, remaining cleanup or lingering processes/worktrees/test data/artifacts, and the natural next action.
- For non-trivial changes, emit an `AGENTS.md` §9 handoff recommending **b-review**. If this is a checkpoint review rather than final branch review, include the completed step or milestone explicitly in the handoff `goal` or `decisions` field.
- Close with the skill-exit status block (`AGENTS.md` §9).

## Rules

- Implement only approved or clearly scoped work.
- Preserve unrelated user changes.
- Do not add opportunistic refactors, compatibility code, or side cleanup.
- Stop for new decisions instead of guessing.
- A small direct request must still pass a real verification step.
- Do not commit unless explicitly asked.
- When the plan is wrong, revise it via `AGENTS.md` §2 — do not silently drift the implementation.
- Preserve durable plan metadata when editing saved plans; do not strip frontmatter while updating progress.

## Common rationalizations

See the suite-wide anti-pattern table in `AGENTS.md` §12. The ones that bite hardest here: opportunistic adjacent fixes, deferring verification to "the end", uncited framework assumptions, and ignoring a dirty workspace.
