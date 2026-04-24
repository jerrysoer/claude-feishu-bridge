#!/usr/bin/env bash
set -euo pipefail

# scripts/uninstall.sh — remove the daemon and (optionally) local config/sessions.

CC_HOME="$HOME/.cc-connect"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }

if command -v cc-connect >/dev/null 2>&1; then
  log "Stopping and removing the cc-connect daemon..."
  cc-connect daemon uninstall || warn "daemon uninstall reported an error (it may not have been installed)"
else
  warn "cc-connect binary not found on PATH — skipping daemon uninstall"
fi

printf '\n'
read -r -p "Also delete $CC_HOME (config, session history, logs)? [y/N] " ans
case "$ans" in
  y|Y|yes|YES)
    rm -rf "$CC_HOME"
    log "Removed $CC_HOME"
    ;;
  *)
    log "Keeping $CC_HOME"
    ;;
esac

printf '\n'
read -r -p "Also uninstall the cc-connect npm binary? [y/N] " ans
case "$ans" in
  y|Y|yes|YES)
    npm uninstall -g cc-connect || warn "npm uninstall reported an error"
    ;;
  *)
    log "Keeping cc-connect binary installed"
    ;;
esac

log "Done."
