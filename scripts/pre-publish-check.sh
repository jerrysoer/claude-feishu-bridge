#!/usr/bin/env bash
set -uo pipefail

# scripts/pre-publish-check.sh — run before pushing to a public remote.
#
# Two gates:
#   1. LEAK CHECK (fatal). Scan for identifying strings that should never ship.
#      Fails with exit 1 on any hit.
#   2. TODO CHECK (warning). Flag placeholders like "TODO-HANDLE" that should be
#      replaced before a real release. Non-fatal — you can still ship a WIP.
#
# Extend LEAK_PATTERNS when you add new content (new bot IDs, new internal names).

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

red()    { printf '\033[1;31m%s\033[0m' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m' "$*"; }
green()  { printf '\033[1;32m%s\033[0m' "$*"; }
blue()   { printf '\033[1;34m%s\033[0m' "$*"; }

# Patterns that must NEVER appear in the repo. Comma-free regex, case-insensitive.
# Edit this list whenever you add real content that could leak identifying info.
LEAK_PATTERNS=(
  # Credentials / IDs from live deployments
  'ou_[0-9a-f]{30,}'       # Feishu open_ids (any real one is 30+ hex chars)
  'cli_[0-9a-f]{15,}'      # Feishu app_ids
  'oc_[0-9a-f]{20,}'       # Feishu chat_ids
  # Add your own patterns below -- employer name, internal project names,
  # dev machine paths, etc. Example:
  # 'acme.?corp'
  # '/Users/myname'
)

# Placeholders that SHOULD be replaced before a real publish, but aren't fatal.
# Note: CHANGEME_ABSOLUTE_PATH is a runtime sentinel that setup.sh sed-substitutes
# at install time; it stays in the repo on purpose and is NOT listed here.
TODO_PATTERNS=(
  # Add your own placeholder patterns below. Example:
  # 'FIXME-BEFORE-RELEASE'
)

# Files/dirs to skip. .git is obvious; the check script itself references the
# patterns literally, so exclude it to avoid self-matching.
EXCLUDES=(
  ':!scripts/pre-publish-check.sh'
  ':!.git'
)

# Prefer `git grep` (respects .gitignore, fast); fall back to grep -r.
if git rev-parse --git-dir >/dev/null 2>&1; then
  search() { git grep -nEI --color=never "$1" -- "${EXCLUDES[@]}" 2>/dev/null; }
else
  search() { grep -rnEI --color=never --exclude-dir=.git --exclude='pre-publish-check.sh' "$1" . 2>/dev/null; }
fi

echo
blue '==> '; echo 'Leak check (fatal)'
leak_hits=0
for pat in "${LEAK_PATTERNS[@]}"; do
  out="$(search "(?i)$pat" || true)"
  # Fallback if -P isn't available: try -E with case-insensitive via (?i)-less approach
  if [ -z "$out" ]; then
    out="$(git grep -nEI -i --color=never "$pat" -- "${EXCLUDES[@]}" 2>/dev/null || true)"
  fi
  if [ -n "$out" ]; then
    leak_hits=$((leak_hits + 1))
    red '  LEAK'; printf ' %s\n' "$pat"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
done

if [ "$leak_hits" -eq 0 ]; then
  green '  OK'; echo ' — no identifying strings found.'
else
  red '  FAIL'; printf ' — %d leak pattern(s) matched. DO NOT PUBLISH.\n' "$leak_hits"
fi

echo
blue '==> '; echo 'TODO check (non-fatal)'
todo_hits=0
for pat in ${TODO_PATTERNS[@]+"${TODO_PATTERNS[@]}"}; do
  out="$(git grep -nEI -i --color=never "$pat" -- "${EXCLUDES[@]}" 2>/dev/null || true)"
  if [ -n "$out" ]; then
    todo_hits=$((todo_hits + 1))
    yellow '  TODO'; printf ' %s\n' "$pat"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
done

if [ "$todo_hits" -eq 0 ]; then
  green '  OK'; echo ' — no remaining placeholders.'
else
  yellow '  WARN'; printf ' — %d placeholder pattern(s) still present. Replace before a real release.\n' "$todo_hits"
fi

echo
blue '==> '; echo 'Executable bits'
bits_ok=1
for f in bin/claude-feishu-bridge scripts/setup.sh scripts/configure.sh scripts/uninstall.sh scripts/pre-publish-check.sh; do
  if [ ! -x "$f" ]; then
    red '  NOT EXECUTABLE'; printf ' %s  (fix: chmod +x %s)\n' "$f" "$f"
    bits_ok=0
  fi
done
[ "$bits_ok" = 1 ] && { green '  OK'; echo ' — all scripts are executable.'; }

echo
blue '==> '; echo 'Git identity (repo-local)'
if git rev-parse --git-dir >/dev/null 2>&1; then
  printf '  user.name  = %s\n' "$(git config user.name || echo '<unset>')"
  printf '  user.email = %s\n' "$(git config user.email || echo '<unset>')"
  printf '  committers: '
  git log --pretty=format:'%ae' 2>/dev/null | sort -u | tr '\n' ' '
  echo
else
  yellow '  WARN'; echo ' — not a git repository yet; run `git init` before publishing.'
fi

echo
if [ "$leak_hits" -gt 0 ]; then
  red '==> FAIL'; echo ' — resolve leaks above before publishing.'
  exit 1
fi

if [ "$todo_hits" -gt 0 ] || [ "$bits_ok" != 1 ]; then
  yellow '==> PASS (with warnings)'; echo ' — safe to commit, but address warnings before a real release.'
  exit 0
fi

green '==> PASS'; echo ' — clean; ready to publish.'
