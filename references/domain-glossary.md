# Domain glossary convention

Use this convention when a repo benefits from a shared language for product terms, bounded contexts, or recurring architectural decisions.

This convention is optional. Do not invent these files as a side effect of ordinary implementation work.

## Files

- `CONTEXT.md` — a glossary for one project or one bounded context.
- `CONTEXT-MAP.md` — only when the repo has multiple bounded contexts and needs to point each one at its own `CONTEXT.md`.
- `docs/adr/` — architectural decisions that are hard to reverse, surprising without context, or the result of a real trade-off.

## `CONTEXT.md` rules

- Keep it as a glossary, not a spec, scratch pad, or implementation notebook.
- Define canonical terms, short meanings, and important relationships.
- Call out ambiguous or overloaded terms explicitly.
- Prefer concise language over exhaustive prose.
- If a term has common wrong aliases, note what to avoid.

## Suggested `CONTEXT.md` shape

```markdown
# <Project or context name>

## Language

**Canonical term**:
Short meaning.
_Avoid_: overloaded alias, old name

## Relationships

- A **Thing A** contains many **Thing B**
- A **Thing B** belongs to one **Thing A**

## Flagged ambiguities

- "old word" previously meant both X and Y — resolved: use **new term** for X
```

## `CONTEXT-MAP.md` rules

- Use it only when one glossary is no longer enough.
- Keep it as a pointer document: context name, owning path, and where its ADRs live.
- Do not duplicate glossary content from child contexts into the map.

## ADR rules

- Use ADRs only for decisions that are hard to reverse, surprising without context, or the result of a real trade-off.
- Keep glossary terms in `CONTEXT.md`; keep implementation history and trade-offs in ADRs.
- Do not create ADRs for obvious, reversible, or purely local choices.

## Skill usage

- `b-spec` should prefer glossary terms when it sharpens a rough request.
- Planning, debugging, testing, and review work may reuse the glossary when the repo already has one.
- If the repo has no glossary, continue normally; this convention is a quality upgrade, not a prerequisite.
