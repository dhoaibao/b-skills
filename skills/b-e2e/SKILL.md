---
name: b-e2e
description: >
  Browser-based end-to-end testing. ALWAYS invoke when the user asks to test the UI, run end-to-end tests, use the browser, or verify frontend flows: "test UI", "chạy E2E", "test trên trình duyệt", "browser test". Uses Playwright to navigate, interact, and assert state. Unlike b-test (which handles unit/integration code tests), b-e2e drives a real browser to test user-facing functionality.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-e2e

$ARGUMENTS

Use a real browser to verify user-facing flows, capture evidence, and optionally turn a
successful manual flow into repo-native browser test code.

## When to use

- The user wants a live browser flow tested.
- The task is UI verification, frontend bug reproduction, or browser-based state inspection.
- The user wants to write or fix an end-to-end browser test.

## When NOT to use

- The task is unit or integration test work without a live browser -> use **b-test**.
- The issue is backend or non-UI runtime debugging -> use **b-debug**.
- The task is planning a feature or flow before implementation -> use **b-plan**.

## Tools required

- Playwright MCP browser tools — navigate, snapshot, click, type, fill, select, hover, drag/drop, upload, dialog handling, tabs, wait, resize, screenshot, evaluate, network, console, and close. Use `playwright_browser_run_code_unsafe` only as a last resort.
- `find_symbol`, `get_symbols_overview`, `insert_before_symbol`, `insert_after_symbol`, `replace_symbol_body` — from `serena` MCP server *(optional, for editing existing browser test files)*.
- `bash` and native file tools — for target health checks, config discovery, manifests, and writing repo test files when needed.

If Playwright MCP is unavailable, stop and say browser automation is unavailable in this session.

Graceful degradation: ❌ Not possible — live browser testing depends on Playwright MCP.

## Steps

### Step 1 — Prepare the run

1. Create a session-specific artifact directory under `.opencode/b-skills/b-e2e/<run-id>/`.
2. Determine the target URL and whether the flow is read-only or stateful.
3. Before touching `localhost`, verify the server is reachable. Do not start a dev server unless the user approves the discovered project command.
4. Clarify only what blocks the flow: auth/session state, test data, and whether writes are allowed.

### Step 2 — Drive the browser

1. Navigate to the page.
2. Capture an accessibility snapshot before interacting.
3. Execute the requested flow with first-class Playwright tools.
4. Wait for specific UI state instead of relying on arbitrary sleeps.

### Step 3 — Verify and collect evidence

1. Re-snapshot or screenshot the relevant state.
2. Use console or network inspection when the UI outcome depends on client errors or API calls.
3. For user-facing layout work, check one desktop and one mobile viewport unless the user explicitly scoped the test to one size.
4. If a step looks flaky, rerun once and report the flake with evidence if the results differ.

### Step 4 — Author or fix browser tests *(optional)*

1. Inspect the repo's existing browser-test setup first: `playwright.config.*`, `cypress.config.*`, package scripts, test directories, and naming conventions.
2. Preserve the repo's current browser-test framework instead of forcing Playwright test files into every project.
3. If no browser-test framework exists and the user wants new test code, ask before introducing one.
4. Translate the successful manual flow into stable test code using accessible selectors and clear assertions.

### Step 5 — Cleanup

1. Close the browser.
2. Clean up only test data created by this run and only when that cleanup was approved.
3. Record artifact paths, generated test files, and cleanup status in the run manifest.

## Output format

```
### b-e2e: [flow]

**URL**: [target]
**Scope**: [flow tested]

#### Interactions
- [step]
- [step]

#### Assertions
- [passed or failed state]

#### Test code
- [none / file updated / file created]

#### Artifacts
- `.opencode/b-skills/b-e2e/<run-id>/`
```

## Rules

- Always use a snapshot before guessing where to click or type.
- Do not start a dev server without approval.
- Do not mutate production-like data without explicit confirmation.
- Preserve the repo's existing browser-test framework when editing test files.
- Do not introduce Playwright test files into a non-Playwright repo unless the user approves that change.
- Keep `playwright_browser_run_code_unsafe` as a tightly scoped last resort.
- Always close the browser when the run is complete.
