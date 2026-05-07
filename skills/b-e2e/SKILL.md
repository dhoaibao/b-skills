---
name: b-e2e
description: >
  ALWAYS invoke when the user asks to test the UI, run end-to-end tests, use the browser, or verify frontend flows: "test UI", "chạy E2E", "test trên trình duyệt", "browser test". Uses Playwright to navigate, interact, and assert state. Unlike b-test (which handles unit/integration code tests), b-e2e drives a real browser to test user-facing functionality.
effort: high
---

# b-e2e

$ARGUMENTS

Drives a real browser using Playwright to verify frontend user flows, interact with elements, inspect the DOM/accessibility tree, and author or debug E2E test scripts.

## When to use
- Running end-to-end (E2E) tests in the browser
- Verifying UI state, visuals, or frontend workflows
- Writing or debugging Playwright/Cypress test files
- Interacting with a running web application to reproduce a bug

## When NOT to use
- Writing or fixing unit tests (use `/b-test`)
- Debugging backend logic or API failures without UI involvement (use `/b-debug`)

## Tools required

- `mcp__playwright__browser_navigate` — from `playwright` MCP server *(Primary)*
- `mcp__playwright__browser_snapshot` — from `playwright` MCP server *(Primary)*
- `mcp__playwright__browser_click` / `browser_fill_form` — from `playwright` MCP server *(Primary)*
- `mcp__playwright__browser_take_screenshot` — from `playwright` MCP server *(Secondary)*
- `mcp__playwright__browser_evaluate` — from `playwright` MCP server *(optional, for complex DOM assertions)*
- `mcp__playwright__browser_network_requests` — from `playwright` MCP server *(optional, for asserting API calls made during a user flow)*
- `find_symbol`, `insert_before_symbol`, `insert_after_symbol`, `replace_symbol_body` — from `serena` MCP server *(optional, for writing test code in Step 5 — adding tests to existing describe blocks or fixing broken test bodies)*
- `Bash` — to manage temporary artifact directories and run dev server health checks

If `playwright` MCP is unavailable: Stop and inform the user that E2E browser interactions require the Playwright MCP server.
If `serena` is unavailable in Step 5: write test code using Bash write tools or the native `Write`/`Edit` tools instead.
Graceful degradation: ❌ Not possible — this skill inherently requires browser automation.

## Steps

### Step 1 — Setup Environment and Navigate

Use the `Bash` tool to ensure the temporary artifact directory exists: `mkdir -p .claude/b-e2e`.

Determine the target URL (local dev server or staging). If the URL is a `localhost` address, verify the dev server is reachable before navigating:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT | grep -qE "^[23]" || echo "Server not responding"
```
If the server is not reachable, ask the user to start it before proceeding. Do not attempt `browser_navigate` to a non-responding host.

Once confirmed reachable (or for remote URLs), call `browser_navigate` to load the application.

### Step 2 — Map the UI and Capture Visuals
Call `browser_snapshot` (saving to `.claude/b-e2e/snapshot.md`) and `browser_take_screenshot` (saving to `.claude/b-e2e/screenshot.png`) to capture the accessibility tree and visual state. Always use the accessibility snapshot to find exact target references before attempting to click or type.

### Step 3 — Execute Interactions
Execute the requested user flow by calling `browser_click`, `browser_fill_form`, `browser_type`, or `browser_press_key` using the precise targets mapped in Step 2.

### Step 4 — Verify State
Capture a new snapshot/screenshot in `.claude/b-e2e/` or use `browser_evaluate` to assert that the expected text, elements, or state changes have appeared on the screen.

### Step 5 — Author or Fix Test Code
If the user asked to write or fix a test file, map the successful manual steps into standard Playwright code and write it to the codebase using Serena's symbolic tools or Bash.

### Step 6 — Cleanup Artifacts
Once testing, verification, and code generation are complete, use the `Bash` tool to clean up all temporary artifacts by running `rm -rf .claude/b-e2e`.

---

## Output format

```
### b-e2e: [flow name]

**URL**: [target URL]
**Scope**: [user flow tested — e.g. "checkout flow", "login → dashboard redirect"]

#### Interactions
- [Action 1: navigate / click / type / fill]
- [Action 2: ...]

#### Assertions
✅ [expected state confirmed — description]
❌ [unexpected state — description and screenshot reference if captured]

#### Network requests *(optional — only if browser_network_requests was used)*
- [Method + URL] — [status / payload note]

#### Test code *(optional — only if writing or fixing a test file)*
```playwright
// Playwright test code
```
Saved to: `[path/to/test.spec.ts]`

#### Cleanup
✅ `.claude/b-e2e/` removed
```

---

## Rules
- Always use `browser_snapshot` to get exact element targets before interacting; never guess selectors blindly.
- Save all intermediate snapshots, screenshots, and visual outputs strictly to `.claude/b-e2e/`.
- Always delete the `.claude/b-e2e/` directory completely when the testing flow finishes.
- Ensure the local dev server is running before attempting to navigate to `localhost`.
- Keep interactions sequential and verify the state changes after major actions (like form submissions).
