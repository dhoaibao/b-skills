#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path('.')
errors = []

skill_paths = sorted(root.glob('skills/*/SKILL.md'))
skill_names = [path.parent.name for path in skill_paths]
agent_paths = sorted(root.glob('agents/*.md'))
agent_names = [path.stem for path in agent_paths]
reference_paths = sorted(root.glob('references/*.md'))
reference_names = [path.name for path in reference_paths]

if not skill_paths:
    errors.append('No skills/*/SKILL.md files found')

if not reference_paths:
    errors.append('No references/*.md files found')

for required_path in ['CLAUDE.md', 'global/CLAUDE.md', 'hooks/b-skills-guard.py', 'settings/b-skills.settings.json', '.b-skills/.gitignore']:
    if not (root / required_path).exists():
        errors.append(f'{required_path}: missing Claude-native runtime source')

b_skills_guard = root / '.b-skills' / '.gitignore'
if b_skills_guard.exists() and b_skills_guard.read_text().splitlines() != ['*', '!.gitignore']:
    errors.append('.b-skills/.gitignore: must ignore artifacts with `*` and keep the guard trackable with `!.gitignore`')

required_sections = [
    '## Claude execution model',
    '## When to use',
    '## When NOT to use',
    '## Tools required',
    '## Steps',
    '## Rules',
]

for path in skill_paths:
    text = path.read_text()
    name = path.parent.name

    if not text.startswith('---\n'):
        errors.append(f'{path}: missing YAML frontmatter start')
        continue

    parts = text.split('---', 2)
    if len(parts) < 3:
        errors.append(f'{path}: missing YAML frontmatter close')
        continue

    frontmatter = parts[1]
    body = parts[2]

    name_match = re.search(r'^name:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
    if not name_match:
        errors.append(f'{path}: missing frontmatter name')
    elif name_match.group(1) != name:
        errors.append(f'{path}: frontmatter name {name_match.group(1)!r} does not match directory {name!r}')

    if re.search(r'^compatibility:\s*opencode\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{path}: stale OpenCode compatibility frontmatter remains')

    if not re.search(r'^user-invocable:\s*true\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{path}: user-invocable must be true')

    if not re.search(r'^disable-model-invocation:\s*false\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{path}: disable-model-invocation must be false')

    if not re.search(r'^\s*suite:\s*b-skills\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{path}: metadata.suite must be b-skills')

    if not re.search(r'^\s*runtime:\s*claude\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{path}: metadata.runtime must be claude')

    execution_match = re.search(r'^\s*execution:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
    agent_match = re.search(r'^agent:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
    if not execution_match:
        errors.append(f'{path}: metadata.execution must be present')
    elif execution_match.group(1) not in {'inline', 'fork'}:
        errors.append(f'{path}: metadata.execution must be inline or fork')
    elif execution_match.group(1) == 'fork':
        if not re.search(r'^context:\s*fork\s*$', frontmatter, re.MULTILINE):
            errors.append(f'{path}: forked skills must set context: fork')
        if not agent_match:
            errors.append(f'{path}: forked skills must point at a concrete agent')
        else:
            agent_path = root / 'agents' / f'{agent_match.group(1)}.md'
            if not agent_path.exists():
                errors.append(f'{path}: agent {agent_match.group(1)!r} not found at {agent_path}')
            else:
                agent_text = agent_path.read_text()
                for required in ['## Boundaries', '- Tool boundary:', '- Permission boundary:', '- Memory boundary:']:
                    if required not in agent_text:
                        errors.append(f'{agent_path}: missing agent boundary marker {required!r}')
                if f'  - {name}' not in agent_text:
                    errors.append(f'{agent_path}: agent skills list must include {name}')
    elif agent_match:
        errors.append(f'{path}: inline skills must not set agent')

    desc_match = re.search(r'^description:\s*>\s*\n(?P<desc>(?:\s+.*\n)+?)(?=^[A-Za-z_-]+:|^metadata:|^---)', frontmatter + '---', re.MULTILINE)
    if not desc_match:
        errors.append(f'{path}: missing block description')
    else:
        desc = ' '.join(line.strip() for line in desc_match.group('desc').splitlines())
        word_count = len(desc.split())
        if word_count > 80:
            errors.append(f'{path}: description has {word_count} words, expected <=80')

    for section in required_sections:
        if section not in body:
            errors.append(f'{path}: missing required section {section!r}')

    forbidden_patterns = [
        r'`write`',
        r'`edit`',
        r'native `edit`',
        r'manual `edit`',
        r'## Boundary examples',
        r'MCP fallback ladder',
        r'\.opencode/b-e2e/',
        r'git diff HEAD~1 HEAD',
        r'Never trigger destructive git commands',
        r'Note: "⚠️ GitNexus unavailable',
    ]
    for pattern in forbidden_patterns:
        if re.search(pattern, text):
            errors.append(f'{path}: forbidden stale runtime pattern {pattern!r}')

    if 'AGENTS.md' in text:
        errors.append(f'{path}: installed runtime skill files must not reference maintainer-only AGENTS.md')

    if name in {'b-research', 'b-test'} and re.search(r'gitnexus', text, re.IGNORECASE):
        errors.append(f'{path}: GitNexus should stay out of this skill workflow')

readme = (root / 'README.md').read_text()
reference = (root / 'REFERENCE.md').read_text()
claude_memory = (root / 'global' / 'CLAUDE.md').read_text() if (root / 'global' / 'CLAUDE.md').exists() else ''
maintainer_guide = (root / 'CLAUDE.md').read_text() if (root / 'CLAUDE.md').exists() else ''
runtime_contract_path = root / 'references' / 'runtime-contract.md'
if not runtime_contract_path.exists():
    errors.append('references/runtime-contract.md: missing detailed runtime contract')
    runtime_contract = ''
else:
    runtime_contract = runtime_contract_path.read_text()
install_sh = (root / 'install.sh').read_text()
settings_path = root / 'settings' / 'b-skills.settings.json'
hook_guard_path = root / 'hooks' / 'b-skills-guard.py'

residual_commands = sorted(root.glob('commands/*.md'))
if residual_commands:
    listed = ', '.join(str(path) for path in residual_commands)
    errors.append(f'commands/: residual command wrappers should be removed from the Claude-native source layout: {listed}')

if (root / 'AGENTS.md').exists():
    errors.append('AGENTS.md: residual maintainer guide should be removed; use root CLAUDE.md for Claude Code source-repo guidance')

if (root / 'global' / 'AGENTS.md').exists():
    errors.append('global/AGENTS.md: residual runtime kernel should be removed; use global/CLAUDE.md plus references/runtime-contract.md')

expected_skill_count = len(skill_paths)
for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference)]:
    doc_lower = doc_text.lower()
    count_matches = {int(value) for value in re.findall(r'\b(\d+)\s*[- ]skill\b', doc_lower)}
    count_matches.update(int(value) for value in re.findall(r'\bsuite of\s+(\d+)\s+skills\b', doc_lower))
    if not count_matches:
        errors.append(f'{doc_path}: missing explicit numeric skill-count claim')
    elif expected_skill_count not in count_matches:
        found = ', '.join(str(value) for value in sorted(count_matches))
        errors.append(f'{doc_path}: skill-count claim {found} does not match repo count {expected_skill_count}')

runtime_boundary_sections = [
    '### Kernel/detail split for the shared sections',
    '`§2 Source of truth`',
    '`§3 Definitions and rubrics`',
    '`§5 Evidence standards`',
    '`§6 Safety gates`',
    '`§7 Execution discipline`',
    '`§8 Artifacts`',
    '`§9 Output contract`',
    '`§10 Cross-cutting decisions`',
    '### Non-trivial work',
    '### Small direct request',
    '### Approval-required actions',
    '### Verification ladder',
    '### Skill-exit status block',
    '### Handoff envelope',
]
for required in runtime_boundary_sections:
    if required not in runtime_contract:
        errors.append(f'references/runtime-contract.md: missing canonical boundary section {required!r}')

runtime_boundary_markers = [
    'Requires sequencing.',
    'No remaining design decision',
    'Required fields are `skill`, `state`, `artifacts`, `next`, `blockers`.',
    'Required fields are `source`, `goal`, `decisions`, `assumptions`, `files`, `verification`, `blockers`, `next-skill`.',
]
for required in runtime_boundary_markers:
    if required not in runtime_contract:
        errors.append(f'references/runtime-contract.md: missing canonical boundary marker {required!r}')

for name in skill_names:
    for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference)]:
        if name not in doc_text:
            errors.append(f'{doc_path}: missing skill mention {name}')
    if f'remove_skill_if_managed {name}' not in install_sh:
        errors.append(f'install.sh: uninstall missing skill removal for {name}')

for name in reference_names:
    for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference)]:
        if name not in doc_text:
            errors.append(f'{doc_path}: missing reference mention {name}')

for ref_path in reference_paths:
    ref_name = ref_path.name
    if ref_name == 'runtime-contract.md':
        continue
    if not any(ref_name in path.read_text() for path in skill_paths):
        errors.append(f'{ref_path}: not referenced by any skill file')

expected_agent_names = set()
for path in skill_paths:
    text = path.read_text()
    parts = text.split('---', 2)
    if len(parts) >= 3:
        frontmatter = parts[1]
        execution_match = re.search(r'^\s*execution:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
        agent_match = re.search(r'^agent:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
        if execution_match and execution_match.group(1) == 'fork' and agent_match:
            expected_agent_names.add(agent_match.group(1))

for agent_path in agent_paths:
    text = agent_path.read_text()
    if not text.startswith('---\n'):
        errors.append(f'{agent_path}: missing YAML frontmatter start')
        continue
    parts = text.split('---', 2)
    if len(parts) < 3:
        errors.append(f'{agent_path}: missing YAML frontmatter close')
        continue
    frontmatter = parts[1]
    name_match = re.search(r'^name:\s*(\S+)\s*$', frontmatter, re.MULTILINE)
    if not name_match:
        errors.append(f'{agent_path}: missing frontmatter name')
    elif name_match.group(1) != agent_path.stem:
        errors.append(f'{agent_path}: frontmatter name {name_match.group(1)!r} does not match filename {agent_path.stem!r}')
    if not re.search(r'^description:\s*>\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{agent_path}: missing block description')
    if not re.search(r'^permissionMode:\s*\S+\s*$', frontmatter, re.MULTILINE):
        errors.append(f'{agent_path}: missing permissionMode boundary')
    if 'skills:' not in frontmatter:
        errors.append(f'{agent_path}: missing skills preload boundary')

extra_agent_names = sorted(set(agent_names) - expected_agent_names)
if extra_agent_names:
    errors.append(f'agents/: agents not referenced by forked skills: {", ".join(extra_agent_names)}')

for required in [
    'CLAUDE.md',
    '## Runtime Kernel',
    '## Routing',
    '## Tool Priority',
    '## Safety And Execution',
    'references/runtime-contract.md',
]:
    if required not in claude_memory:
        errors.append(f'global/CLAUDE.md: missing runtime memory marker {required!r}')

for required in [
    'CLAUDE_DIR="$HOME/.claude"',
    'MEMORY_SRC="$LOCAL_REPO/global/CLAUDE.md"',
    'SKILLS_DST="$CLAUDE_DIR/skills"',
    'AGENTS_DST="$CLAUDE_DIR/agents"',
    'HOOKS_DST="$CLAUDE_DIR/hooks"',
    'REFERENCES_DST="$CLAUDE_DIR/references/b-skills"',
    'SETTINGS_DST="$CLAUDE_DIR/settings.json"',
    'CLAUDE_JSON="$HOME/.claude.json"',
    'merge_claude_settings',
    'json_merge_mcp_config',
]:
    if required not in install_sh:
        errors.append(f'install.sh: missing Claude-native installer marker {required!r}')

if 'remove_command_if_managed' in install_sh:
    errors.append('install.sh: stale OpenCode command uninstall logic remains')

for forbidden in ['OPENCODE_DIR', 'opencode.json', '~/.config/opencode', 'Install OpenCode']:
    if forbidden in install_sh:
        errors.append(f'install.sh: stale OpenCode installer marker remains: {forbidden!r}')

script_path_markers = {
    'install.sh': ['CLAUDE_DIR/skills', 'CLAUDE_DIR/agents', 'CLAUDE_DIR/hooks', 'CLAUDE_DIR/settings.json'],
    'scripts/smoke-install.sh': ['.claude/skills', '.claude/agents', '.claude/hooks', '.claude/settings.json'],
}
for script_path, required_markers in script_path_markers.items():
    script_text = (root / script_path).read_text()
    for required in required_markers:
        if required not in script_text:
            errors.append(f'{script_path}: missing Claude path coverage {required!r}')
    for forbidden in ['~/.config/opencode', '.config/opencode', 'opencode.json', 'OpenCode config']:
        if forbidden in script_text:
            errors.append(f'{script_path}: stale OpenCode path remains: {forbidden!r}')

for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference), ('CLAUDE.md', maintainer_guide)]:
    for required in ['~/.claude/', 'CLAUDE.md', 'global/CLAUDE.md', 'settings/b-skills.settings.json', 'hooks/b-skills-guard.py']:
        if required not in doc_text:
            errors.append(f'{doc_path}: missing Claude-native layout marker {required!r}')
    for forbidden in ['~/.config/opencode', 'opencode.json', 'compatibility: opencode']:
        if forbidden in doc_text:
            errors.append(f'{doc_path}: stale OpenCode path/field remains: {forbidden!r}')

if not hook_guard_path.exists():
    errors.append('hooks/b-skills-guard.py: missing Claude governance hook guard')
else:
    hook_guard = hook_guard_path.read_text()
    for required in ['DENY_PATTERNS', 'ASK_PATTERNS', 'permissionDecision', '--session-start']:
        if required not in hook_guard:
            errors.append(f'hooks/b-skills-guard.py: missing governance marker {required!r}')

if not settings_path.exists():
    errors.append('settings/b-skills.settings.json: missing Claude settings template')
else:
    try:
        settings = json.loads(settings_path.read_text())
    except json.JSONDecodeError as exc:
        errors.append(f'settings/b-skills.settings.json: invalid JSON: {exc}')
        settings = {}
    hooks = settings.get('hooks', {}) if isinstance(settings, dict) else {}
    for event in ['SessionStart', 'PreToolUse', 'PermissionRequest']:
        if event not in hooks:
            errors.append(f'settings/b-skills.settings.json: missing hook event {event}')
    permissions = settings.get('permissions', {}) if isinstance(settings, dict) else {}
    for bucket in ['ask', 'deny']:
        if not permissions.get(bucket):
            errors.append(f'settings/b-skills.settings.json: permissions.{bucket} must not be empty')
    settings_text = settings_path.read_text() if settings_path.exists() else ''
    for required in ['b-skills-guard.py', 'Bash(npm install*)', 'Bash(git commit*)', 'Bash(terraform apply*)']:
        if required not in settings_text:
            errors.append(f'settings/b-skills.settings.json: missing governance setting {required!r}')

for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference), ('CLAUDE.md', maintainer_guide), ('global/CLAUDE.md', claude_memory), ('references/runtime-contract.md', runtime_contract)]:
    if '.opencode/b-e2e/' in doc_text:
        errors.append(f'{doc_path}: old E2E artifact path still present')

for doc_path, doc_text in [('README.md', readme), ('CLAUDE.md', maintainer_guide), ('global/CLAUDE.md', claude_memory), ('references/runtime-contract.md', runtime_contract)]:
    if 'Opus 4.7' in doc_text:
        errors.append(f'{doc_path}: model-specific reasoning wording should not be present')

if '@modelcontextprotocol/server-sequential-thinking' in install_sh:
    errors.append('install.sh: sequential-thinking should not be bundled in the MCP defaults')

for doc_path, doc_text in [('README.md', readme), ('REFERENCE.md', reference), ('CLAUDE.md', maintainer_guide), ('references/runtime-contract.md', runtime_contract)]:
    if 'sequential-thinking' in doc_text:
        errors.append(f'{doc_path}: sequential-thinking should be fully removed from suite docs and maintainer guidance')

for required in ['Radar/hands boundary', 'Evidence standards', 'GitNexus freshness gate', 'Patch discipline', 'Token budget']:
    if required not in runtime_contract:
        errors.append(f'references/runtime-contract.md: missing detailed convention {required!r}')

for required in ['missing expected lines', 'stale context', 'one small hunk']:
    if required not in runtime_contract:
        errors.append(f'references/runtime-contract.md: patch discipline missing phrase {required!r}')

for doc_path, doc_text in [('REFERENCE.md', reference)]:
    if 'Good triggers' in doc_text or 'Boundary examples' in doc_text:
        errors.append(f'{doc_path}: duplicated trigger examples should stay in README/skills, not reference')

root_required = [
    'optional radar',
    'primary hands',
    'indexed, fresh, and target-aware',
    'only when indexing is safe',
]
for required in root_required:
    if required not in maintainer_guide:
        errors.append(f'CLAUDE.md: missing GitNexus/Serena contract phrase {required!r}')

root_forbidden = [
    'Prefer GitNexus first for graph-shaped code tasks when the repo is indexed:',
    'when GitNexus is available and indexed',
    'Note: "⚠️ GitNexus unavailable',
    'key Vietnamese + English trigger phrases',
    'global/AGENTS.md',
    'commands/<name>.md',
]
for forbidden in root_forbidden:
    if forbidden in maintainer_guide:
        errors.append(f'CLAUDE.md: stale maintainer guidance remains: {forbidden!r}')

b_plan = (root / 'skills' / 'b-plan' / 'SKILL.md').read_text()
b_implement = (root / 'skills' / 'b-implement' / 'SKILL.md').read_text()
if 'Update saved-plan checkboxes' in b_implement and '- [ ] **<imperative step title>**' not in b_plan:
    errors.append('skills/b-plan/SKILL.md: saved-plan skeleton must support checkbox-style progress updates used by b-implement')

patch_skill_expectations = {
    'b-implement': 'global patch discipline',
    'b-refactor': 'global patch discipline',
    'b-test': 'global patch discipline',
    'b-debug': 'global patch discipline',
}
for skill_name, required_phrase in patch_skill_expectations.items():
    skill_text = (root / 'skills' / skill_name / 'SKILL.md').read_text()
    if required_phrase not in skill_text:
        errors.append(f'skills/{skill_name}/SKILL.md: missing canonical patch discipline reference {required_phrase!r}')
    for duplicated_phrase in ['missing expected lines', 'stale context recovery']:
        if duplicated_phrase in skill_text:
            errors.append(f'skills/{skill_name}/SKILL.md: duplicated patch protocol phrase {duplicated_phrase!r}')

if 'stable anchors' not in b_plan:
    errors.append('skills/b-plan/SKILL.md: prose/config plans should mention stable anchors for patchable edits')

for required in ['Do not promote to full mode solely', '2-5 bullets']:
    if required not in b_plan:
        errors.append(f'skills/b-plan/SKILL.md: missing low-ceremony planning guard {required!r}')

b_test = (root / 'skills' / 'b-test' / 'SKILL.md').read_text()
for required in ['failing test path', 'verification target']:
    if required not in b_test:
        errors.append(f'skills/b-test/SKILL.md: missing TDD handoff field {required!r}')

for required in ['Daily-use fast path examples', 'trivial happy-path runs']:
    if required not in runtime_contract:
        errors.append(f'references/runtime-contract.md: missing happy-path convention {required!r}')

stale_reindex_prefix = 'If any GitNexus tool warns the index is stale, run `'
if stale_reindex_prefix in maintainer_guide and '--skip-agents-md' not in maintainer_guide:
    errors.append('CLAUDE.md: stale GitNexus reindex guidance remains: missing `--skip-agents-md`')

if errors:
    print('Skill validation failed:', file=sys.stderr)
    for error in errors:
        print(f'- {error}', file=sys.stderr)
    raise SystemExit(1)

print(f'Skill validation passed ({len(skill_paths)} skills).')
PY
