#!/usr/bin/env bash
# sync-check.sh — validate the public/ folder's skill + plugin structure.
#
# Works identically in two contexts:
#   - inside the heltarchat monorepo (script lives at public/skills/scripts/)
#   - inside the published Heltar/heltar-dev mirror (script lives at skills/scripts/)
#
# Both layouts share the same internal shape:
#
#   <root>/
#   ├── docs/
#   ├── skills/
#   │   └── scripts/sync-check.sh   ← this file
#   └── heltar-plugins/
#
# So the script only needs to find <root> by walking up from itself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_ROOT="$(cd "$SKILLS_ROOT/.." && pwd)"
DOCS_ROOT="$PUBLIC_ROOT/docs"
PLUGIN_ROOT="$PUBLIC_ROOT/heltar-plugins"

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
gray()  { printf "\033[90m%s\033[0m\n" "$*"; }

errors=0
checks=0
check_pass() { gray "  ✓ $1"; checks=$((checks + 1)); }
check_fail() { red   "  ✗ $1"; errors=$((errors + 1)); checks=$((checks + 1)); }

# Collect existing skill slugs (used for uses: validation).
declare -a SKILL_SLUGS=()
for d in "$SKILLS_ROOT"/skills/heltar-*; do
  [ -d "$d" ] || continue
  SKILL_SLUGS+=("$(basename "$d")")
done

skill_exists() {
  for s in "${SKILL_SLUGS[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

# Each skill must have a SKILL.md with frontmatter, valid references, existing uses.
for skill_dir in "$SKILLS_ROOT"/skills/heltar-*; do
  [ -d "$skill_dir" ] || continue
  slug="$(basename "$skill_dir")"
  rel_skill="${skill_dir#$PUBLIC_ROOT/}"

  skill_md="$skill_dir/SKILL.md"
  if [ ! -f "$skill_md" ]; then
    check_fail "$rel_skill — missing SKILL.md"
    continue
  fi
  if ! head -1 "$skill_md" | grep -q '^---$'; then
    check_fail "$rel_skill/SKILL.md — missing opening frontmatter delimiter"
  elif ! awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' "$skill_md"; then
    check_fail "$rel_skill/SKILL.md — missing closing frontmatter delimiter"
  else
    check_pass "$rel_skill/SKILL.md — frontmatter present"
  fi

  declared_name="$(awk '/^---$/{c++; next} c==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "$skill_md")"
  if [ -z "$declared_name" ]; then
    check_fail "$rel_skill/SKILL.md — frontmatter has no name field"
  elif [ "$declared_name" != "$slug" ]; then
    check_fail "$rel_skill/SKILL.md — name '$declared_name' does not match folder '$slug'"
  fi

  # references/api-reference.md must resolve into docs/
  ref="$skill_dir/references/api-reference.md"
  rel_ref="${ref#$PUBLIC_ROOT/}"
  if [ ! -e "$ref" ]; then
    check_fail "$rel_ref — missing"
  else
    resolved="$(readlink -f "$ref")"
    case "$resolved" in
      "$DOCS_ROOT"/*) check_pass "$rel_ref → $(echo "$resolved" | sed "s|$PUBLIC_ROOT/||")" ;;
      *)              check_fail "$rel_ref — resolves outside docs/ ($resolved)" ;;
    esac
  fi

  # references/guides/*.md (where present) must also resolve into docs/
  if [ -d "$skill_dir/references/guides" ]; then
    for g in "$skill_dir/references/guides"/*.md; do
      [ -e "$g" ] || continue
      rel_g="${g#$PUBLIC_ROOT/}"
      gresolved="$(readlink -f "$g")"
      case "$gresolved" in
        "$DOCS_ROOT"/*) check_pass "$rel_g → $(echo "$gresolved" | sed "s|$PUBLIC_ROOT/||")" ;;
        *)              check_fail "$rel_g — resolves outside docs/ ($gresolved)" ;;
      esac
    done
  fi

  # uses: entries refer to existing skills
  uses_block="$(awk '
    /^---$/ { c++; next }
    c==1 && /^[[:space:]]+uses:/ {
      in_uses=1
      sub(/^.*uses:[[:space:]]*/,"")
      if (length($0) > 0 && $0 != "[]") print
      next
    }
    c==1 && in_uses && /^[[:space:]]+-/ { sub(/^[[:space:]]+-[[:space:]]*/,""); print; next }
    c==1 && in_uses && !/^[[:space:]]/ { in_uses=0 }
    c==2 { exit }
  ' "$skill_md")"

  while IFS= read -r dep; do
    [ -z "$dep" ] && continue
    dep="$(echo "$dep" | tr -d '[:space:]')"
    if ! skill_exists "$dep"; then
      check_fail "$rel_skill/SKILL.md — uses: '$dep' does not exist as a skill"
    else
      check_pass "$slug uses → $dep"
    fi
  done <<< "$uses_block"
done

# Plugin's skills bundle: must resolve to the skills folder.
PLUGIN_BUNDLE="$PLUGIN_ROOT/plugins/heltar-claude-plugin/skills"
if [ -e "$PLUGIN_BUNDLE" ]; then
  resolved="$(readlink -f "$PLUGIN_BUNDLE")"
  if [ "$resolved" = "$SKILLS_ROOT/skills" ]; then
    check_pass "heltar-plugins/.../skills → skills/skills"
  else
    check_fail "heltar-plugins/.../skills resolves to $resolved (expected $SKILLS_ROOT/skills)"
  fi
fi

# JSON config files parse cleanly.
validate_json() {
  local f="$1"
  local rel="${f#$PUBLIC_ROOT/}"
  [ ! -f "$f" ] && return
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" >/dev/null 2>&1; then
    check_pass "$rel — valid JSON"
  else
    check_fail "$rel — invalid JSON"
  fi
}
validate_json "$PLUGIN_ROOT/.claude-plugin/marketplace.json"
validate_json "$PLUGIN_ROOT/plugins/heltar-claude-plugin/.claude-plugin/plugin.json"

echo
if [ "$errors" -eq 0 ]; then
  green "✓ sync-check passed — $checks check(s)"
  exit 0
else
  red "✗ sync-check failed — $errors error(s) across $checks check(s)"
  exit 1
fi
