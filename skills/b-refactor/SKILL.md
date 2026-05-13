---
name: b-refactor
description: >
  Code refactoring: impact analysis, mechanical transformation, and verification. ALWAYS invoke when the user asks to refactor, tái cấu trúc, rename, extract method, move, inline, simplify, or clean up a named target with behavior-preserving scope. Vague cleanups go to b-plan first. Unlike b-plan (decides what to build), b-refactor owns mechanical edits.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-refactor

$ARGUMENTS

Handle behavior-preserving mechanical code changes: lock the exact target, map the
impact radius, apply the smallest safe transformation, and verify that references still
hold.

If `$ARGUMENTS` is provided, treat it as the refactoring instruction and proceed directly.

## When to use

- User asks to rename, extract, move, inline, delete dead code, or simplify a named target.
- The requested transformation is meant to preserve behavior.
- The scope is concrete enough to execute without re-deciding product behavior.

## When NOT to use

- The request is broad, vague, or partly a feature change -> use **b-plan** first.
- The work is mainly implementing new behavior -> use **b-implement**.
- The task is a runtime bug fix -> use **b-debug**.
- The task is a test-only failure or test rewrite -> use **b-test**.
- The request is only an external API lookup -> use **b-research**.

## Tools required

- `bash` — inspect git state and run project-specific checks.
- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `search_for_pattern`, `get_diagnostics_for_file`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`, `rename_symbol`, `safe_delete_symbol` — from `serena` MCP server *(preferred for exact target locking, reference mapping, and symbol-aware edits)*.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for multi-phase or high-risk refactor ordering)*.
- `gitnexus` — from `gitnexus` MCP server *(optional radar for broad exported/shared impact when indexed and fresh)*.

Fallbacks follow the global MCP rules. Without Serena, continue only when native search plus careful `apply_patch` edits are still safe enough for the requested scope.

Graceful degradation: ⚠️ Partial — small local refactors remain possible, but cross-file renames and safe deletes are riskier without symbol-aware tooling.

## Steps

### Step 1 — Lock the target

1. Resolve the exact symbol or file to change.
2. If the request starts from a usage site, helper import, interface, or repeated code shape, use `find_declaration`, `find_implementations`, or `search_for_pattern` before editing.
3. If symbol-aware work is needed, call `check_onboarding_performed`; if false, call `onboarding` once.
4. If the request is still vague after a short inspection, ask the smallest question needed to make the target concrete.

### Step 2 — Assess impact and verification depth

1. Use `find_referencing_symbols` to map call sites and usages.
2. Treat **trivial local refactors** as a fast path when all of these are true:
   - one file
   - no exported/public contract change
   - few or no external references
   - behavior clearly preserved
3. For shared, exported, multi-file, route/tool, or package-boundary refactors, optionally use GitNexus to scope the blast radius before editing.
4. For medium or high-risk refactors, discover the baseline verification command from project scripts or CI config. If baseline checks are already failing, stop and ask before proceeding.

### Step 3 — Apply the mechanical transform

Choose the smallest matching transformation:

- rename symbol -> `rename_symbol`
- delete dead code -> `safe_delete_symbol`
- extract or split function -> insert helper, then update caller
- inline local logic -> update caller, then remove old symbol safely
- move code between files -> add destination first, then update imports and remove origin

Use `apply_patch` only for import updates, config, prose, or non-symbol glue.

If the work turns into a behavioral redesign instead of a mechanical transform, stop and hand it back to **b-plan**.

### Step 4 — Verify

1. Run `get_diagnostics_for_file` on touched files when supported.
2. Run the narrowest typecheck, build, or test command that matches the risk level.
3. Re-check references when the target is shared or exported.
4. Inspect `git diff` to confirm the change stayed within intended scope.
5. If failures indicate a real regression, use **b-debug**. If they indicate test-mechanic drift, use **b-test**.

## Output format

```
### b-refactor: [transformation]

**Target**: [symbol or file]
**Risk**: [trivial / low / medium / high]
**Impact**: [key references or boundaries]

#### Changes
- `[path:line]` — [what changed]

#### Verification
```bash
[command]
```
[result]

#### Follow-up
- [none / remaining step / user decision needed]
```

## Rules

- Keep the task behavior-preserving; do not quietly add features while refactoring.
- Use the trivial-local fast path only when the risk is genuinely small and the contract is untouched.
- Use symbol-aware rename/delete tools whenever they fit the requested transformation.
- Ask before broad directory moves or other changes that can cascade through tooling, docs, and imports.
- Do not keep going through failing medium/high-risk verification without surfacing the blocker.
- Do not commit unless the user explicitly asks.
