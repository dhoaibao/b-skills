---
name: b-review
description: >
  Pre-PR changed-code review. ALWAYS invoke for "code review", "review before PR", "kiểm tra logic", "what would a reviewer flag", or after implementation is done. Do NOT invoke for UI/design review, plan review, research synthesis review, or repository/skill audit unless the user asks for PR-style code review. Unlike b-test, b-review judges adequacy and risk; it does not primarily write tests.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-review

$ARGUMENTS

Review changed code the way a strong reviewer would: prioritize blockers, verify that
the diff matches the intended behavior, and surface real regression or security risk
before PR.

If `$ARGUMENTS` is provided, treat it as the requirements pointer or summary. If it
contains `skip test adequacy`, skip the test-adequacy and observability parts.

## When to use

- The user wants a pre-PR or pre-commit changed-code review.
- The goal is to find correctness, regression, security, edge-case, or coverage risks.
- The implementation is done and needs reviewer-style scrutiny.

## When NOT to use

- Something is broken and needs root-cause tracing -> use **b-debug**.
- The task is writing or fixing tests -> use **b-test**.
- The task is external docs or API lookup -> use **b-research**.
- The request is plan review, UX critique, or repository audit rather than PR-style code review.

## Tools required

- `bash` — inspect `git diff`, `git status`, and narrow verification commands when needed.
- `check_onboarding_performed`, `onboarding`, `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `find_declaration`, `find_implementations`, `get_diagnostics_for_file` — from `serena` MCP server *(preferred for impact-first code inspection)*.
- `resolve-library-id`, `query-docs` — from `context7` MCP server *(optional, for suspicious third-party API usage in the diff)*.
- `firecrawl_scrape` — from `firecrawl` MCP server *(optional, for issue/ticket URL context when a plan references one)*.
- `brave_web_search` — from `brave-search` MCP server *(optional, for focused CVE or risky-pattern lookups)*.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for blocker vs suggestion classification when ambiguity remains)*.
- `gitnexus` — from `gitnexus` MCP server *(optional radar for broad route/API/tool/shared-flow review risk when indexed and fresh)*.

Fallbacks follow the global MCP rules. If optional tools are unavailable, continue with a narrower manual review and label the limitation only when it affects confidence.

Graceful degradation: ✅ Possible — review still works with `bash`, native file tools, and focused source inspection.

## Steps

### Step 1 — Get the diff and review mode

1. Read `git diff HEAD` and `git status --short`.
2. If there is no diff, ask the user which commit, branch, or range to review. Do not silently fall back to `HEAD~1`.
3. Treat a diff of `<=50 lines` and `<=2 files` as fast path.
4. If the diff is very large, ask the user which area to prioritize first.

### Step 2 — Establish the baseline

1. Use `$ARGUMENTS`, an approved plan file, or a short user clarification to define what the change was supposed to do.
2. If a selected plan references an issue URL, optionally scrape it for context.
3. If no concrete baseline is available after bounded clarification, continue in clearly labeled **diff-only risk review** mode.

### Step 3 — Inspect the highest-risk changes

1. If the diff is graph-shaped or contract-heavy, optionally use GitNexus once to identify the risky boundaries.
2. If symbol-aware inspection is useful, call `check_onboarding_performed`; if false, call `onboarding` once.
3. Review in impact-first order:
   - changed symbols with the broadest references
   - service boundaries, route handlers, or tool handlers
   - code that claims to satisfy explicit requirements
4. Always check correctness, error handling, input validation, auth/authz changes, sensitive-data exposure, and injection risk.
5. Use diagnostics or a narrow verification command only when review confidence depends on runtime or typed-language evidence.

### Step 4 — Assess coverage and operability

1. If a baseline exists, map requirements to the diff and flag missing or partial coverage.
2. Check edge cases and test adequacy for the changed behavior unless `skip test adequacy` was requested.
3. Check observability only for new or changed entry points, handlers, jobs, or consumers.

### Step 5 — Report findings

1. Put findings first, ordered by severity.
2. Use `sequentialthinking` only if blocker classification is genuinely unclear.
3. If there are no findings, say so explicitly and note any residual risk or skipped verification.

## Output format

```
### b-review: [task or diff]

**Diff scope**: [files changed, rough size, fast-path yes/no]
**Baseline**: [plan / arguments / user-stated / unavailable]
**Mode**: [requirements-based / diff-only risk review]

#### Findings
- [severity] `[path:line]` — [issue] -> [expected behavior]

#### Coverage / Tests / Observability
- Requirements: [covered / missing / not assessed]
- Tests: [adequate / gaps / skipped]
- Observability: [adequate / gaps / skipped]

#### Verdict
**[READY FOR PR / NEEDS FIXES]**
```

## Rules

- Findings come first; summaries are secondary.
- Do not claim requirements coverage when no baseline exists.
- Do not run broad automated checks by default; use only the narrow evidence needed.
- Security checks for changed entry points, sensitive-data handling, and injection risk are never skipped.
- If the logic cannot be confirmed confidently from the available evidence, say so instead of guessing.
