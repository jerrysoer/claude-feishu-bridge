#!/usr/bin/env bash
set -euo pipefail

# scripts/configure.sh — lock the bot to a single Feishu user_id and start the daemon.
#
# Usage: configure.sh ou_<hex_user_id>

CONFIG_PATH="$HOME/.cc-connect/config.toml"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

user_id="${1:-}"
[ -z "$user_id" ] && die "Usage: claude-feishu-bridge configure <user_id>

Get your user_id by DMing the bot /whoami in Feishu."

case "$user_id" in
  ou_*) ;;
  *) die "Invalid user_id: '$user_id'. Expected something starting with ou_ (see /whoami)." ;;
esac

[ -f "$CONFIG_PATH" ] || die "No config found at $CONFIG_PATH. Run 'claude-feishu-bridge setup' first."

# Portable sed in-place: use a .tmp suffix then delete, works on both BSD and GNU sed.
escaped="$(printf '%s' "$user_id" | sed 's|[\\/&]|\\&|g')"

# Uncomment the two placeholder lines. Idempotent — running twice is harmless.
sed -i.tmp \
  -e "s|^# *admin_from = \"ou_XXXXXXXX\"|admin_from = \"$escaped\"|" \
  -e "s|^# *allow_from = \"ou_XXXXXXXX\"|allow_from = \"$escaped\"|" \
  "$CONFIG_PATH"
rm -f "$CONFIG_PATH.tmp"

# If the lines were already uncommented (re-run), overwrite whatever value is there.
sed -i.tmp \
  -e "s|^admin_from = \"ou_[^\"]*\"|admin_from = \"$escaped\"|" \
  -e "s|^allow_from = \"ou_[^\"]*\"|allow_from = \"$escaped\"|" \
  "$CONFIG_PATH"
rm -f "$CONFIG_PATH.tmp"

log "Wrote admin_from / allow_from = $user_id"

log "Installing cc-connect daemon..."
cc-connect daemon install --config "$CONFIG_PATH" --force

sleep 1
cc-connect daemon status

cat <<'EOF'

────────────────────────────────────────────────────────────
Done. The bot is now locked to your user_id and the daemon is running.

Try it: DM the bot

    list the files in work_dir

You should see a rolling progress card, then a file listing.

Troubleshooting: claude-feishu-bridge logs -f
Restart after config edits: claude-feishu-bridge restart
────────────────────────────────────────────────────────────
EOF
