---
name: b-spec
description: >
  Clarify what to build before planning. ALWAYS invoke when the request is
  underspecified, the desired end state or acceptance criteria are unclear, or
  the user has a rough idea that needs a concrete scope. Extract goals,
  constraints, and success criteria, then hand off to b-plan or b-implement.
  Unlike b-plan, b-spec decides the target outcome before sequencing work.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-spec

$ARGUMENTS

Clarify the end state before planning or coding. Turn a rough ask into a concrete goal, constraints, and acceptance criteria.

If `$ARGUMENTS` is present, treat it as the rough request and proceed directly. Ask only the smallest questions needed to make the target outcome concrete.

## When to use

- The request is underspecified or has multiple plausible interpretations.
- The desired end state, acceptance criteria, or non-goals are still unclear.
- The user has a rough feature idea and needs it turned into something plannable.
- The codebase context may answer part of the ambiguity, but not the intended outcome.

## When NOT to use

- The goal is already clear and the next question is sequencing or implementation approach → use **b-plan**.
- The request already meets the **small direct request** threshold in `AGENTS.md` §3 and the behavior is obvious → use **b-implement**.
- The blocker is external feasibility, vendor docs, or library behavior → use **b-research**.
- Something is broken and needs diagnosis → use **b-debug**.

## Tools required

- `serena-symbol-toolkit` *(preferred for checking existing behavior, ownership, or nearby conventions before asking the user)*
- `gitnexus-radar` *(optional, for unfamiliar shared surfaces or route/tool context)*
- `context7-docs` *(optional, for a narrow feasibility check discovered during clarification)*

Fallbacks: `AGENTS.md` §4. If clarification reveals a genuine external-knowledge blocker, stop and use **b-research**. Graceful degradation: ✅ Possible — native reads plus a short clarification loop still work.

## Steps

### Step 1 — Decide whether discovery is actually needed

Stay in **b-spec** only while the target outcome is underdetermined.

- If the goal, constraints, and success criteria are already clear, hand off immediately:
  - **b-implement** when the request meets the **small direct request** threshold in `AGENTS.md` §3.
  - **b-plan** when the work is non-trivial and the open question is how to sequence it.
- If two or more plausible outcomes remain, continue.

### Step 2 — Clarify the target outcome

Restate the ask in one sentence, then ask only the blocking questions needed to lock:

- user-visible outcome
- hard constraints
- success criteria
- explicit non-goals when scope could sprawl

Use the clarification budget from `AGENTS.md` §1. Do not turn this into an open-ended interview.

Prefer one blocking question at a time when the answer will change the next question. If a single concrete scenario will collapse the ambiguity faster than abstract discussion, ask for that scenario instead.

**Hard 2-round exit.** A "round" is one user response after a clarification ask, regardless of how many sub-questions that ask contained. If after two such rounds the user still cannot name a user-visible outcome or pick between plausible interpretations, **stop asking**. Propose 2 concrete interpretations explicitly, name the assumption each one rests on, and ask the user to pick one or override. Never loop a third round of open clarification.

### Step 3 — Collapse ambiguity from local evidence

Before asking the user to decide something the codebase already answers:

- Use `serena-symbol-toolkit` to inspect the existing behavior, naming, nearby patterns, or owning area.
- Use `gitnexus-radar` only when the question is graph-shaped or the area is unfamiliar.
- If a single narrow docs/API check would settle feasibility, use `context7-docs` inline.

When the repo already has `CONTEXT.md` or `CONTEXT-MAP.md`, read it first and reuse its canonical terminology. If the user uses a vague or overloaded term, name the ambiguity, propose the narrowest wording that matches the glossary, and ask for confirmation only if code and docs do not already settle it.

When the user describes current behavior or boundaries, cross-check that claim against the code before accepting it. If the code and the request disagree, surface the contradiction explicitly instead of building the spec on top of it.

If the remaining blocker is broader external research, stop and hand off to **b-research**.

### Step 4 — Produce the minimal spec

Keep the output in chat by default. Produce a compact, execution-ready spec:

```text
### Spec: <goal>

**Goal:** <what should exist or change>
**Constraints:** <hard boundaries>
**Acceptance criteria:**
- <testable outcome>
- <testable outcome>
**Non-goals:** <what this request is not asking for>
**Assumptions:** <what the spec takes for granted that the user did not explicitly confirm, or `none`>
```

Always include an **Assumptions** line, even when empty (`Assumptions: none`). Spec without assumptions silently becomes a contract the user did not agree to.

Do not create a separate saved artifact by default; this spec is the input to the next skill.

### Step 5 — Hand off cleanly

- Hand off to **b-implement** when the clarified request is now small and obvious.
- Hand off to **b-plan** when the goal is now clear but the work still needs sequencing, dependencies, or risk management.

Carry the spec's `Assumptions` into the handoff envelope's `assumptions` field (`AGENTS.md` §9) so the downstream skill sees what was taken for granted. Decisions the user explicitly confirmed go to `decisions`; the rest are assumptions.

Close with the handoff envelope and, for non-trivial clarification work, the skill-exit status block (`AGENTS.md` §9).

## Output format

```text
### Spec: [goal]

**Goal:** [what should happen]
**Constraints:** [hard boundaries]
**Acceptance criteria:**
- [testable outcome]
- [testable outcome]
**Non-goals:** [excluded scope]
**Assumptions:** [what the spec takes for granted that the user did not explicitly confirm, or `none`]
**Next:** [b-plan / b-implement / b-research]
```

## Reference pointers

- `references/domain-glossary.md` (installed under `~/.config/opencode/references/b-skills/`) — optional glossary convention for `CONTEXT.md`, `CONTEXT-MAP.md`, and ADR usage when the repo already carries domain docs.

## Rules

- Clarify the end state; do not turn this skill into implementation planning.
- Prefer repository evidence over user questions when the codebase already answers the ambiguity.
- Ask only the minimum questions needed to make the work safely plannable.
- If one concrete scenario or counterexample will expose the real boundary faster than abstraction, use it.
- If the repo already has a glossary, prefer its terms over ad-hoc wording.
- Keep the output compact; avoid writing a second durable artifact unless the user explicitly asks for one.
- If clarification reveals that the real blocker is external feasibility, stop and use **b-research** instead of guessing.
