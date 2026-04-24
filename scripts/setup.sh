#!/usr/bin/env bash
set -euo pipefail

# scripts/setup.sh — bootstrap a fresh cc-connect install for Claude Code + Feishu.
#
# Steps:
#   1. Platform / toolchain checks.
#   2. Install cc-connect globally if missing.
#   3. Stage a config template at ~/.cc-connect/config.toml.
#   4. Prompt for the Claude Code work_dir and patch the template.
#   5. Run `cc-connect feishu setup` so the user can scan the QR.

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CC_HOME="$HOME/.cc-connect"
CONFIG_PATH="$CC_HOME/config.toml"
TEMPLATE="$ROOT/templates/config.toml"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

# --- 1. Platform / toolchain ---------------------------------------------------

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) die "Unsupported platform: $(uname -s). macOS and Linux only." ;;
esac

command -v npm >/dev/null 2>&1 || die \
  "npm not found. Install Node.js 18+ first (try: brew install node, or https://nodejs.org, or nvm/fnm)."

node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$node_major" -lt 18 ]; then
  die "Node.js 18+ required (you have $(node -v 2>/dev/null || echo unknown))."
fi

# --- 2. Install cc-connect -----------------------------------------------------

if command -v cc-connect >/dev/null 2>&1; then
  log "cc-connect already installed ($(cc-connect --version 2>&1 | head -1))"
else
  log "Installing cc-connect globally via npm..."
  npm install -g cc-connect
fi

# --- 3. Stage config -----------------------------------------------------------

mkdir -p "$CC_HOME"

if [ -f "$CONFIG_PATH" ]; then
  backup="$CONFIG_PATH.bak-$(date +%s)"
  warn "Existing config at $CONFIG_PATH — backing up to $backup"
  cp "$CONFIG_PATH" "$backup"
fi

cp "$TEMPLATE" "$CONFIG_PATH"
log "Staged config template at $CONFIG_PATH"

# --- 4. Prompt for work_dir ----------------------------------------------------

default_workdir="$(pwd)"
printf '\n'
read -r -p "Absolute path where Claude Code should operate [$default_workdir]: " workdir
workdir="${workdir:-$default_workdir}"

case "$workdir" in
  /*) ;;
  *) die "work_dir must be an absolute path (got: $workdir)" ;;
esac

# sed -i differs between BSD (macOS) and GNU. Portable form: sed -i.bak then rm.
escaped_workdir="$(printf '%s' "$workdir" | sed 's|[\\/&]|\\&|g')"
sed -i.tmp "s|CHANGEME_ABSOLUTE_PATH|$escaped_workdir|" "$CONFIG_PATH"
rm -f "$CONFIG_PATH.tmp"

log "work_dir set to: $workdir"

# --- 5. Feishu QR onboarding ---------------------------------------------------

cat <<'EOF'

────────────────────────────────────────────────────────────
Next: Feishu QR onboarding.

cc-connect will print a QR code and a URL. Either:
  • Scan the QR with the Feishu mobile app, OR
  • Open the printed URL in a browser where you're signed into Feishu.

After authorizing, the bot will be created in your tenant and its
credentials will be written into ~/.cc-connect/config.toml automatically.

Press Enter to continue.
────────────────────────────────────────────────────────────
EOF
read -r _

cc-connect feishu setup --project default

cat <<'EOF'

────────────────────────────────────────────────────────────
Almost done.

1. Open Feishu. The new bot should appear in your contacts —
   its name is set during the QR onboarding flow.

2. DM the bot: /whoami
   It will reply with your user_id (a string like ou_xxxxxx).

3. Lock the bot to your account and start the daemon:

     claude-feishu-bridge configure ou_YOUR_USER_ID

Until step 3 finishes, the daemon is NOT running and the bot is
NOT locked to you — anyone in your tenant who finds the bot could
talk to it. Complete the configure step before sharing anything.
────────────────────────────────────────────────────────────
EOF
