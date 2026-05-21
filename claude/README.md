# Claude Code Runtime Layout

This directory contains Claude Code runtime templates that are copied or referenced by `install.sh`.

## Supported distribution mode

The first Claude-native release supports a personal-global install only:

- Kernel memory: `~/.claude/CLAUDE.md`
- Skills: `~/.claude/skills/<skill-name>/SKILL.md`
- Skill-local shared references: `~/.claude/skills/<skill-name>/references/b-agentic/*.md`
- Suite metadata, backups, and source snapshots: `~/.claude/b-agentic/`
- Shared reference snapshot: `~/.claude/b-agentic/references/*.md`
- Recommended settings template: `~/.claude/b-agentic/templates/settings.recommended.json`
- Project MCP template: `~/.claude/b-agentic/templates/mcp.project.template.json`
- Sensitive artifacts: `~/.claude/b-agentic/<skill>/<run-id>/` or `/tmp/claude-code/b-agentic/<skill>/<run-id>/`
- Temporary logs: `/tmp/claude-code/b-agentic/<skill>/<slug>.log`

Project-local `.claude/` install, plugin packaging, hooks, and dynamic context injection are non-goals for the first migrated release. Add them only after validator and smoke coverage prove global parity.

## Invocation policy

Claude Code exposes each skill directory as `/b-*`. Mutating or coordinating skills are manual-only through `disable-model-invocation: true`. Read-only discovery and review skills may remain model-invocable when their descriptions are tight and do not grant tools.

## Safety policy

The installer never overwrites an existing `~/.claude/CLAUDE.md` without `--replace-memory`. Settings and MCP templates are copied as inert templates by default. Users may apply them with `--install-settings`, `--replace-settings`, `--install-project-mcp`, or `--replace-project-mcp`; replace modes create timestamped backups first.
