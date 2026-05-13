---
name: b-research
description: >
  External knowledge, from quick lookup to full research. ALWAYS invoke when the user says "research", "tìm hiểu", "deep dive", "so sánh", "tổng hợp", "lookup", "tra cứu nhanh", "what's the API for", "method signature of X", or "config key for Y". Auto-detects quick vs full mode. Unlike b-debug or b-plan, it fetches docs/web info instead of tracing code or choosing implementation.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-research

$ARGUMENTS

Handle external knowledge with the lightest mode that can answer correctly. Start with
direct lookup when possible, move to source-backed synthesis only when the question or
evidence quality requires it.

If `$ARGUMENTS` is provided, treat it as the research question and proceed directly.

## When to use

- Library, framework, SDK, or API questions.
- Config keys, method signatures, setup details, capability checks, or migration facts.
- Comparisons, deep dives, cited reports, recency-sensitive topics, or multi-source synthesis.
- Questions about known URLs, local docs, PDFs, spreadsheets, or other source material.

## When NOT to use

- Runtime bug tracing or root-cause analysis -> use **b-debug**.
- Deciding what to build or how to sequence work -> use **b-plan**.
- Pre-PR review of changed code -> use **b-review**.

## Tools required

- `resolve-library-id`, `query-docs` — from `context7` MCP server *(primary for library/framework API lookups)*.
- `brave_web_search`, `brave_news_search`, `brave_image_search` — from `brave-search` MCP server *(search, news, and visual-reference discovery as needed)*.
- `firecrawl_search`, `firecrawl_scrape`, `firecrawl_parse` — from `firecrawl` MCP server *(source-backed page and local-document reading)*.
- `firecrawl_map`, `firecrawl_interact`, `firecrawl_interact_stop`, `firecrawl_extract` — from `firecrawl` MCP server *(optional, for JS-heavy pages or structured extraction)*.
- `firecrawl_agent`, `firecrawl_agent_status` — from `firecrawl` MCP server *(last resort for deep autonomous research only after simpler paths fail)*.
- `sequentialthinking` — from `sequential-thinking` MCP server *(optional, for resolving materially conflicting sources)*.

Fallbacks follow the global MCP rules. If Context7 is unavailable, use official docs via search. If Firecrawl is unavailable, continue only when search results or known official sources are enough and label the answer as limited when confidence drops.

Graceful degradation: ⚠️ Partial — quick lookup remains strong with Context7 or authoritative search; deep source-backed work is weaker without page tools.

## Steps

### Step 1 — Classify the mode

Choose the lightest mode that can answer correctly:

- **Quick lookup** — one fact, one API detail, one config key, a yes/no capability, or a tiny example.
- **Source-backed answer** — one or more concrete sources must be read before answering confidently.
- **Deep research** — comparison, report, multi-source synthesis, recency-sensitive topic, or user-requested deep dive.

If the user already provided a URL, local file path, or document, go directly to extraction instead of doing open-ended search.

### Step 2 — Gather evidence

For quick lookup:

1. Use Context7 first for library or framework APIs.
2. Otherwise run one focused web search.
3. Answer immediately only when the result is authoritative and directly responsive.
4. Cap quick mode at 2 tool calls and do not scrape in quick mode.

For source-backed or deep research:

1. Prefer official docs, release notes, source repos, and vendor materials first.
2. Use news search for recency-sensitive topics and image search only for genuinely visual questions.
3. Scrape or parse only the highest-signal pages or local documents.
4. Use structured extraction when the user needs fields, params, prices, or other structured data.
5. If a page is JS-heavy, try `firecrawl_map` or `firecrawl_interact` before escalating further.
6. Use `firecrawl_agent` only after search plus scrape/map/interact are insufficient, or when the user explicitly asks for deep autonomous research.

### Step 3 — Synthesize

1. Answer only from gathered evidence.
2. For quick lookup, stay concise and direct.
3. For source-backed or deep research, cite the sources that support the answer.
4. Note freshness or limitations when the answer depends on recent information or incomplete access.
5. If authoritative sources materially disagree, use `sequentialthinking` when available to explain the best fit.

## Output format

### Quick lookup

```
### [topic]

[1-3 sentence direct answer]

**Example:** *(optional)*
```[lang]
[minimal example when it helps]
```

**Source**: [Context7 or authoritative URL]
```

### Source-backed or deep research

```
## [research question]

### Answer
[direct answer]

### Key findings
- [finding]
- [finding]

### Limitations
- [gap, staleness, or unavailable source]

### Sources
- [title](URL)
- Context7 (`library-id`) for [feature]
```

## Rules

- Never ask the user to choose between lookup and research; `b-research` decides and escalates itself.
- Use the lightest mode that can answer correctly.
- Do not send private stack traces, internal URLs, customer data, secrets, or proprietary code to public web tools without explicit approval; sanitize queries when possible.
- Never scrape in quick mode.
- Use Context7 first for library and framework API questions.
- Prefer 2-4 authoritative sources over a wide pile of weak ones.
- Do not force an example block for fact-only quick answers.
- If only one authoritative source supports the answer, label it as single-source rather than pretending broader confirmation exists.
- Do not use `firecrawl_agent` before the simpler search + scrape/map/interact path unless the user explicitly wants deep autonomous research.
- Use a `Limitations` section instead of filling factual gaps from prior model knowledge.
