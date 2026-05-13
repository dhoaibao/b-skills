---
name: b-plan
description: >
  Think before coding. ALWAYS invoke when the user says "plan", "thiết kế", "how should I approach", "lên kế hoạch", "nên bắt đầu từ đâu", or the task spans more than 2 files or has unclear scope. Decomposes work, chooses an approach, and writes execution-ready plans. Unlike b-implement, b-plan decides what to build; it does not execute approved steps.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-plan

$ARGUMENTS

Think before coding. Lock scope, choose the smallest viable approach, and produce a plan that a fresh agent can execute without re-deciding the work.

If `$ARGUMENTS` is present, treat it as the task description and proceed. Ask only for missing context that blocks safe planning.

## When to use

- The task is broad, unclear, or likely spans more than 2 files.
- There are multiple valid approaches and the choice matters.
- The user wants a plan, architecture direction, or ordered implementation steps.
- A refactor is still vague and not yet a concrete rename, extract, move, inline, or delete.

## When NOT to use

- The task is a trivial local edit and can be done directly.
- The user already approved a clear plan or gave a small clearly scoped implementation request -> use **b-implement**.
- The request is a concrete behavior-preserving mechanical transformation -> use **b-refactor**.
- The blocker is external docs or library behavior -> use **b-research**.
- Something is broken -> use **b-debug**.

## Tools required

- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for real approach trade-offs or decomposition ambiguity)*.
- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `search_for_pattern` — from `serena` MCP server *(preferred for planning against existing code)*.
- `resolve-library-id`, `query-docs` — from `context7` MCP server *(optional, for a narrow library/API check discovered during planning)*.
- `firecrawl_scrape` — from `firecrawl` MCP server *(optional, for an issue or ticket URL the user already provided)*.
- `gitnexus` — from `gitnexus` MCP server *(optional radar for graph-shaped planning when indexed and fresh)*.

Fallbacks follow the global MCP rules. If the task depends on broader external research, stop and use **b-research** instead of stretching planning into research.

Graceful degradation: ✅ Possible — planning still works with native reads plus inline reasoning.

## Steps

### Step 1 — Pick the lightest planning mode

Choose the lightest mode that still removes ambiguity:
- **Quick mode**: clear scoped work, low risk, usually local, no schema change, no public contract change. Return a concise 2–5 step chat plan with a verification step.
- **Full mode**: unclear, multi-layer, high-risk, or more than 2 files. Write a saved plan to `.opencode/b-plans/`.

Choose the mode yourself. Only ask the user when both modes are genuinely valid and their preference changes the output.

Escalate quick -> full if discovery reveals broad references, unclear requirements, public contract risk, security-sensitive behavior, or deployment risk.

### Step 2 — Lock scope and decisions

State the interpreted scope in one sentence.

If the task is still ambiguous, ask the smallest set of questions that blocks safe planning:
- end state
- hard constraints
- success criteria

Record confirmed decisions as short implementation-ready statements. If a decision is behavioral, contractual, or naming-related and the codebase cannot answer it, ask the user instead of inferring it.

If the task depends on unresolved external research that affects feasibility, architecture, contracts, security, or migration order, stop and use **b-research** before finishing the plan.

### Step 3 — Scan existing code when relevant

Skip this step for greenfield work.

Use GitNexus only when the task is graph-shaped or the area is unfamiliar. Stop once the subsystem, route, consumer set, or boundary is clear.

Then use Serena in this order:
1. `check_onboarding_performed` -> `onboarding` if needed.
2. `find_symbol` for the main owner.
3. `search_for_pattern` when the task is described by behavior or code shape instead of a stable symbol.
4. `get_symbols_overview` on the relevant files.
5. `find_declaration` when the task points to a call site or helper usage.
6. `find_implementations` for interfaces or abstract contracts.
7. `find_referencing_symbols` on shared symbols.
8. Native `read` only for the exact section still needed.

If the user already provided an issue URL, you may scrape it as planning context. Do not pause the workflow just to ask for a ticket link.

### Step 4 — Choose the approach only if it matters

If there is a real structural choice, list 2–3 viable approaches, compare them against the current constraints, choose one, and record why.

If the approach is obvious, skip this step. Do not invent fake alternatives.

### Step 5 — Decompose into execution steps

Produce 3–8 dependency-ordered steps. Each step should say:
- what changes
- exact file paths or symbol names when known
- why now
- how to verify `Done when`

For full-mode plans, also include:
- `## Confirmed decisions`
- `## Planned touch points`
- `## Dependencies`
- `## Risks`
- `## Unknowns`

Add deployment notes only when they are real: feature flags, migration order, external dependency readiness, or rollback risk.

If the task involves field mapping or protocol translation, add a small mapping outline instead of burying it in prose.

### Step 6 — Deliver the plan

Quick mode:
- keep the plan in chat
- ask for approval
- hand approved execution to **b-implement** unless the user explicitly asks to continue in the same session

Full mode:
- write an English plan to `.opencode/b-plans/<task-slug>.md`
- show the saved path
- ask for approval

The plan is complete only when a fresh agent could execute it without re-deriving the design.

## Rules

- Do not implement while planning.
- Keep quick plans lean; do not turn every small task into a full document.
- Save only full-mode plans to `.opencode/b-plans/`.
- Surface blocking unknowns instead of hiding them in vague prose.
- Broad or unclear refactors stay in **b-plan** until they reduce to concrete mechanical steps for **b-refactor**.
- After approval, treat the approved plan as the execution source of truth.
