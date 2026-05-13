---
name: b-test
description: >
  Test-driven development, test debugging, and test coverage evaluation. ALWAYS invoke when the user asks about writing tests, fixing failing tests, test coverage gaps, or TDD: "test", "viết test", "failing test", "test đang fail", "bắt đầu bằng test", "test coverage", "missing test". Unlike b-debug (traces runtime bugs), b-test focuses on test-specific failures: wrong assertions, missing mocks, setup issues, coverage gaps.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-test

$ARGUMENTS

Own code-level test work: write tests, fix test-only failures, and evaluate coverage
without treating every red test as proof that production code is wrong.

If `$ARGUMENTS` is provided, treat it as the test task or failing symptom and proceed
directly.

## When to use

- User asks to write tests for new or existing behavior.
- A test is failing and the likely issue is assertion logic, mocks, fixtures, setup, or timing.
- User asks about coverage gaps or missing regression tests.
- User says: "test", "viết test", "test case", "failing test", "test coverage",
  "TDD", "unit test", "integration test", "test đang fail", "bắt đầu bằng test",
  or "missing test".

## When NOT to use

- The failing test likely exposes a real runtime or product bug -> use **b-debug**.
- The task is browser-driven UI verification or a live user flow -> use **b-e2e**.
- Scope or acceptance is still unclear -> use **b-plan**.
- The request is a pre-PR logic review -> use **b-review**.
- The task is only an external docs or testing-framework lookup -> use **b-research**.

## Tools required

- `bash` — run project test and coverage commands, inspect failure output.
- Native file tools — discover test files, manifests, and focused source/test sections.
- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `get_diagnostics_for_file`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol` — from `serena` MCP server *(preferred for mapping tests to source behavior and editing existing test code)*.
- `resolve-library-id`, `query-docs` — from `context7` MCP server *(optional, for verifying testing framework APIs or matcher behavior)*.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for ambiguous unit vs integration strategy choices)*.

Fallbacks follow the global MCP rules. Without Serena, discover tests with native tools and edit carefully with `apply_patch`. Without Context7 or `sequentialthinking`, keep the same flow and note the limitation only if it affects confidence.

Graceful degradation: ✅ Possible — the core workflow still works with native file tools, `bash`, and `apply_patch`.

## Steps

### Step 1 — Discover framework and scope

1. Locate the relevant test files and the project-specific test commands from manifests or CI config.
2. If the user named a failing test, start from the narrowest runnable target for that test.
3. If symbol-aware inspection is useful, call `check_onboarding_performed`; if false, call `onboarding` once.
4. Use Serena to map the relationship between test and source code:
   - `find_symbol` for the named test or source symbol.
   - `find_declaration` when the test points to a helper, import, or usage rather than the owning definition.
   - `find_implementations` when the target behavior sits behind an interface or polymorphic boundary.
   - `get_symbols_overview` on the test file when setup, fixtures, or grouped cases matter.

Goal: know the framework, the narrowest command to run, and the exact behavior under test.

### Step 2 — Choose the lane

Pick one lane and stay in it:

- **Failing test** — fix the test, fixture, setup, or clearly confirmed production bug.
- **Write tests** — add new regression, unit, or integration coverage for known behavior.
- **Coverage review** — identify the highest-value missing tests and optionally add the top ones.

If the failure might reflect a real product bug and the correct behavior is not already confirmed, switch to **b-debug** instead of guessing from test output alone.

### Step 3 — Fix or add tests

For a failing test:

1. Run the narrowest test command.
2. If output is large, capture it under `/tmp/opencode/b-skills/b-test/` and inspect the failure section instead of truncating it.
3. Read the failing test and the source behavior it exercises.
4. Classify the issue:
   - wrong assertion after behavior confirmation
   - missing mock or stub
   - leaked shared state or fixture drift
   - async timing or missing await
   - environment/setup problem
   - snapshot or golden drift after intentional behavior change
   - real product bug -> switch to **b-debug** unless the root cause is already confirmed and the fix is minimal

For new tests:

1. Identify the behavior, branches, and edge cases that matter.
2. Choose unit or integration scope; hand browser-driven flows to **b-e2e**.
3. Cover happy path, edge cases, error handling, and the regression that would catch an accidental revert.
4. Prefer local fixtures unless the repo already has a shared fixture that fits the scenario.

For coverage review:

1. Discover the project's existing coverage command before inventing one.
2. Rank gaps by requirement coverage, service boundaries, and widely referenced symbols.
3. Optionally add the top 1-3 missing tests when the user wants implementation, not just analysis.

Prefer Serena insertions for existing test bodies. Use `apply_patch` when creating a new test file or when a small non-symbol edit is clearer.

### Step 4 — Verify

1. Run `get_diagnostics_for_file` on touched files when the language supports it.
2. Re-run the narrowest relevant tests.
3. Widen to a broader suite only when the change touches shared fixtures/helpers, public contracts, or the repo's normal test workflow requires it.
4. Use a maximum of 3 local fix/verify loops before reporting what still fails.

## Output format

```
### b-test: [test task]

**Type**: [failing test / write tests / coverage review]
**Framework**: [jest / vitest / pytest / go test / cargo test / other]
**Scope**: [unit / integration / mixed]

#### Findings
- `[path]` — [what was wrong or what behavior needed coverage]

#### Changes
- `[path:line]` — [test fix or test added]

#### Verification
```bash
[command]
```
[result]

#### Remaining gaps
- [none / uncovered case / follow-up suggestion]
```

## Rules

- Never change production code just because a test is red.
- If production behavior is uncertain, switch to **b-debug** before patching source.
- Never update an assertion, snapshot, or golden file without confirming the intended behavior first.
- Browser-driven user flows belong to **b-e2e**; keep `b-test` focused on code-level tests.
- Prefer behavior assertions over implementation-detail assertions.
- Keep fixture, mock, and setup changes as local as practical.
- State when broader suite coverage was skipped and why the narrower check was sufficient.
