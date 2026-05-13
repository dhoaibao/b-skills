---
name: b-implement
description: >
  Execute approved plans safely. ALWAYS invoke when the user says "implement", "execute plan", "thực hiện", "làm theo plan", or after /b-plan approval with scoped work. Reads `.opencode/b-plans/` or an approved chat plan, applies the next small step, verifies it, and stops for new decisions. Unlike b-plan, b-implement changes code.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-implement

$ARGUMENTS

Execute approved or clearly scoped work with discipline: load the source of truth, change the next smallest step, verify it, and stop when a new decision appears.

If `$ARGUMENTS` is present, treat it as the plan path, plan slug, approved chat plan, or small direct implementation request.

## When to use

- The user approved a saved plan or chat plan.
- The task is already scoped and the next action is to edit code or docs.
- The request is small and concrete enough to implement directly without a planning pass.

## When NOT to use

- Scope or acceptance criteria are still unclear -> use **b-plan**.
- The request is a named rename, extract, move, inline, or delete -> use **b-refactor**.
- The task is only external lookup -> use **b-research**.
- The task is only tests -> use **b-test**.
- Something is broken and root cause is not confirmed -> use **b-debug**.

## Tools required

- `bash` — inspect status, diff, and run verification commands.
- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `search_for_pattern`, `get_diagnostics_for_file`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`, `rename_symbol`, `safe_delete_symbol` — from `serena` MCP server *(preferred for symbol-aware edits)*.
- `resolve-library-id`, `query-docs` — from `context7` MCP server *(optional, for a narrow API uncertainty discovered mid-step)*.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for failure triage or step-order ambiguity)*.
- `gitnexus` — from `gitnexus` MCP server *(optional radar for shared route, tool, or exported-boundary changes when indexed and fresh)*.

Fallbacks follow the global MCP rules. If execution reveals a new research blocker, stop and use **b-research**.

Graceful degradation: ✅ Possible — native tools can still implement, but broad symbol changes are riskier without Serena.

## Steps

### Step 1 — Load the source of truth

Resolve scope in this order:
1. a saved plan path
2. a plan slug under `.opencode/b-plans/`
3. an explicitly approved chat plan
4. a small clearly scoped direct request

If the request is broad, multi-file, or still ambiguous, stop and use **b-plan** instead of improvising.

Extract only what execution needs:
- confirmed decisions
- planned touch points
- ordered steps or the single scoped request
- verification expectations
- unresolved blockers

### Step 2 — Check the working state

Run `git status --short` and inspect only the files relevant to the current step.

- Leave unrelated changes alone.
- If the target file already has unrelated edits, patch around them.
- If user changes directly conflict with the approved scope, stop and ask.

If the plan is multi-step, choose the next dependency-ready step. If the request is a tiny direct task, treat it as a one-step implementation and do not invent extra ceremony.

### Step 3 — Implement the next smallest step

For code changes, initialize Serena once, then work in this order:
1. locate the owner with `find_symbol` or `search_for_pattern`
2. inspect structure with `get_symbols_overview`
3. use `find_declaration` or `find_implementations` when the plan starts from usage or an abstract boundary
4. use `find_referencing_symbols` for shared or exported behavior
5. use GitNexus only when the step changes a route, tool contract, or shared boundary and the graph question is still unresolved
6. apply the smallest edit that satisfies the step

If the step turns into an unplanned rename, move, extract, inline, or delete, stop and hand off to **b-refactor**.

If a new behavioral or product decision appears, stop and ask.

### Step 4 — Verify before moving on

Run the exact plan verification when available. Otherwise run the narrowest relevant check for the touched area.

Use `get_diagnostics_for_file` before broader commands when the language supports it.

Classify failures:
- implementation mistake -> fix and rerun
- test harness problem -> **b-test**
- runtime/root-cause uncertainty -> **b-debug**
- unresolved library/API behavior -> Context7, then **b-research** if still unclear

Use the global 3-iteration limit per step.

### Step 5 — Record progress and finish cleanly

After a step passes verification:
- update saved-plan checkboxes when a saved plan exists
- keep the diff limited to approved scope
- continue to the next step only if there is one

At the end:
- inspect `git diff`
- run the final relevant verification
- recommend **b-review** for non-trivial changes

## Rules

- Implement only approved or clearly scoped work.
- Preserve unrelated user changes.
- Do not add opportunistic refactors, compatibility code, or side cleanup.
- Stop for new decisions instead of guessing.
- Small direct implementation requests may stay lightweight, but they still need a real verification step.
- Do not commit unless explicitly asked.
