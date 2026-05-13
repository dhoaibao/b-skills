---
name: b-debug
description: >
  Systematic hypothesis-driven debugging. ALWAYS invoke when the user says "debug", "bug", "lỗi", "không chạy", "fix this", "why is X not working", or pastes an error message. Traces execution paths, confirms root cause, then fixes and verifies by default. Unlike b-test, b-debug owns runtime behavior failures, not test mechanics.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-debug

$ARGUMENTS

Trace the bug, confirm root cause, apply the smallest safe fix, and verify the result. Do not patch before the cause is explicit.

If `$ARGUMENTS` includes a symptom, error, or stack trace, start from it directly. If the user asked only for diagnosis, stop after the confirmed root cause and proposed fix.

## When to use

- The user reports a runtime bug, broken behavior, or error message.
- A test likely exposes a real product bug rather than a test harness issue.
- The failure path may cross middleware, async boundaries, configuration, or multiple modules.

## When NOT to use

- The problem is clearly a test assertion, mock, fixture, or setup issue -> use **b-test**.
- The task is external docs or API lookup only -> use **b-research**.
- The task is a new feature or scoped implementation request -> use **b-plan** or **b-implement**.

## Tools required

- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `search_for_pattern`, `get_diagnostics_for_file`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`, `rename_symbol`, `safe_delete_symbol` — from `serena` MCP server *(preferred for tracing and focused fixes)*.
- Native search and read tools — exact error strings, config keys, repeated patterns, and narrow source reads.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, when several root-cause hypotheses remain plausible)*.
- `resolve-library-id`, `query-docs` — from `context7` MCP server *(optional, for suspected library/API misuse)*.
- `brave_web_search`, `firecrawl_scrape`, `firecrawl_map` — from web tools *(optional, for known public library or framework errors)*.
- `gitnexus` — from `gitnexus` MCP server *(optional radar for unfamiliar cross-module paths when indexed and fresh)*.

Fallbacks follow the global MCP rules. If the only safe next step is external research, sanitize first or ask for approval.

Graceful degradation: ✅ Possible — native analysis still works, but cross-file tracing is slower without Serena.

## Steps

### Step 1 — Frame the symptom

Collect only what is needed to begin:
- exact error or observable failure
- expected behavior
- actual behavior
- reproduction notes if they matter

If the stack trace or a diagnostic already points to one obvious function or file, mark it as a fast path and skip broad hypothesis generation later.

### Step 2 — Map the execution path

Use GitNexus only when the path is unfamiliar, graph-shaped, or route/consumer oriented. Stop once the likely subsystem or boundary is identified.

Then use Serena in this order:
1. `check_onboarding_performed` -> `onboarding` if needed
2. `find_symbol` for the entry point or likely owner
3. `get_symbols_overview` on the relevant files
4. `find_referencing_symbols` for callers or consumers
5. `find_declaration` for suspicious helper usage or imports
6. `find_implementations` for interfaces or abstract contracts
7. `search_for_pattern` when behavior is easier to describe than a symbol name
8. native exact-string search and narrow `read`

Map where data or control can stop, mutate, or silently fail.

### Step 3 — Use cheap checks before broad experimentation

Always search the codebase for the exact error string or log text when it exists.

If the symptom points to a public library or framework error, you may search the web and scrape the top public results. Before doing that:
- do not send private stack traces, internal URLs, customer data, or proprietary code to public web tools without approval
- sanitize the query when possible

If the failure looks like API misuse, verify the exact method or option with Context7 before guessing.

If multiple hypotheses remain, rank them by likelihood and cheapest verification step. Skip this ranking when the fast path already isolates one clear cause.

### Step 4 — Confirm root cause

Start with the cheapest verification:
- local diagnostics
- narrow repro command already present in the project
- targeted temporary logging at one choke point
- config or environment confirmation when relevant

If static analysis is insufficient, use up to 3 instrumentation or repro rounds. Remove temporary probes before finalizing the fix.

State the root cause explicitly before editing:
`Root cause: X because Y.`

### Step 5 — Apply the minimal fix

Keep the fix narrow:
- use Serena symbol edits when the change is clearly symbol-scoped
- use `apply_patch` for small line-level fixes inside a larger symbol
- add a brief comment only when the fix would otherwise be non-obvious

Do not roll broader cleanup or unrelated refactors into the bug fix.

### Step 6 — Verify the fix

Run the narrowest relevant command or procedure that proves the symptom changed.

If the fix affects config or process startup, tell the user whether a restart or reload is required.

If the fix touched several files or a shared boundary, recommend **b-review** before commit.

## Rules

- Never patch before confirming root cause.
- Default to the full loop: trace -> confirm -> fix -> verify.
- Use the obvious-stack-trace fast path when one file or function is already strongly implicated.
- Treat swallowed errors, auth gates, config drift, and async order issues as common first suspects.
- Keep fixes minimal and remove temporary instrumentation before reporting success.
