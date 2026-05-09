#!/usr/bin/env bash
# install.sh — Bootstrap or update b-skills for OpenCode
# Usage:
#   First time / update:
#     curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash
#
# Optional environment overrides:
#   B_SKILLS_REPO  — git URL to clone (default: https://github.com/dhoaibao/b-skills.git)
#   B_SKILLS_DIR   — local clone path (default: $HOME/.b-skills)
#   B_SKILLS_REF   — git ref to check out after clone/pull (default: leave on default branch)

set -euo pipefail

readonly REPO_URL="${B_SKILLS_REPO:-https://github.com/dhoaibao/b-skills.git}"
readonly LOCAL_REPO="${B_SKILLS_DIR:-$HOME/.b-skills}"
readonly REF="${B_SKILLS_REF:-}"
readonly OPENCODE_DIR="$HOME/.config/opencode"
readonly SKILLS_SRC="$LOCAL_REPO/skills"
readonly COMMANDS_SRC="$LOCAL_REPO/commands"
readonly RULES_SRC="$LOCAL_REPO/global/AGENTS.md"
readonly RULES_DST="$OPENCODE_DIR/instructions/b-skills.md"
readonly CONFIG_FILE="$OPENCODE_DIR/opencode.json"
readonly TIMESTAMP="$(date +%Y%m%d%H%M%S)"

log()     { printf '%s
' "$*"; }
section() { printf '
── %s %s
' "$*" "$(printf '%.0s─' $(seq 1 $((60 - ${#1}))))"; }
warn()    { printf '⚠️  %s
' "$*" >&2; }
die()     { printf '❌ %s
' "$*" >&2; exit 1; }

trap 'rc=$?; [ $rc -ne 0 ] && warn "install.sh failed at line $LINENO (exit $rc)"' EXIT

require_bin() {
  command -v "$1" >/dev/null 2>&1 || die "Required binary not found: $1"
}

require_bin git
require_bin python3
command -v opencode >/dev/null 2>&1 || warn "opencode CLI not found — files will still be installed, but you should install OpenCode before using them."

sync_directory() {
  local source_dir="$1" target_dir="$2"
  [ -d "$source_dir" ] || die "sync_directory: source missing: $source_dir"
  [ "$source_dir" = "$target_dir" ] && die "sync_directory: source and target identical"

  mkdir -p "$(dirname "$target_dir")"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  cp -R "$source_dir"/. "$target_dir"/
}

merge_opencode_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  local existing
  existing=$(cat "$CONFIG_FILE" 2>/dev/null || echo '{}')

  local merged
  merged=$(env EXISTING="$existing" RULES_DST="$RULES_DST" python3 - <<'PYEOF'
import json, os

existing_raw = os.environ.get("EXISTING", "{}")
rules_dst = os.environ["RULES_DST"]

try:
    config = json.loads(existing_raw) if existing_raw.strip() else {}
except json.JSONDecodeError:
    config = {}

instructions = config.setdefault("instructions", [])
if rules_dst not in instructions:
    instructions.append(rules_dst)

permission = config.setdefault("permission", {})
skill_permission = permission.setdefault("skill", {})
skill_permission.setdefault("*", "allow")

print(json.dumps(config, indent=2))
PYEOF
)

  local tmp="${CONFIG_FILE}.tmp-${TIMESTAMP}"
  printf '%s
' "$merged" > "$tmp"
  mv "$tmp" "$CONFIG_FILE"
}

section "Sync b-skills repo"
if [ -d "$LOCAL_REPO/.git" ]; then
  if [ -n "$(git -C "$LOCAL_REPO" status --porcelain)" ]; then
    die "Local changes detected in $LOCAL_REPO — commit or stash before re-running."
  fi
  log "🔄 Updating $LOCAL_REPO"
  git -C "$LOCAL_REPO" pull --ff-only || die "git pull --ff-only failed. Resolve in $LOCAL_REPO and re-run."
else
  log "📦 Cloning $REPO_URL → $LOCAL_REPO"
  git clone "$REPO_URL" "$LOCAL_REPO"
fi

if [ -n "$REF" ]; then
  log "🏷  Checking out ref: $REF"
  git -C "$LOCAL_REPO" checkout "$REF"
fi

section "Install OpenCode skills"
[ -d "$SKILLS_SRC" ] || die "Missing skills source directory: $SKILLS_SRC"
mkdir -p "$OPENCODE_DIR/skills"
synced_skills=0
for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  sync_directory "$skill_dir" "$OPENCODE_DIR/skills/$skill_name"
  synced_skills=$((synced_skills + 1))
done
log "✅ Skills synced: $synced_skills → $OPENCODE_DIR/skills"

section "Install OpenCode commands"
[ -d "$COMMANDS_SRC" ] || die "Missing commands source directory: $COMMANDS_SRC"
mkdir -p "$OPENCODE_DIR/commands"
synced_commands=0
for command_file in "$COMMANDS_SRC"/*.md; do
  [ -f "$command_file" ] || continue
  cp "$command_file" "$OPENCODE_DIR/commands/"
  synced_commands=$((synced_commands + 1))
done
log "✅ Commands synced: $synced_commands → $OPENCODE_DIR/commands"

section "Install shared instructions"
mkdir -p "$(dirname "$RULES_DST")"
cp "$RULES_SRC" "$RULES_DST"
merge_opencode_config
log "✅ Rules installed: $RULES_DST"
log "✅ Config updated: $CONFIG_FILE"

section "MCP prerequisites"
log "Configure these MCP servers in OpenCode if you want full functionality:"
log "- serena"
log "- context7"
log "- brave-search"
log "- firecrawl"
log "- playwright"
log "- sequential-thinking"

section "Done"
log "✅ b-skills installed successfully for OpenCode."
log "   Skills:       $OPENCODE_DIR/skills"
log "   Commands:     $OPENCODE_DIR/commands"
log "   Instructions: $RULES_DST"
log "   Config:       $CONFIG_FILE"

trap - EXIT
