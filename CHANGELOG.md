# Changelog

## [0.1.0] - 2026-04-23

Initial public release.

### Features

- One-command setup: `./bin/claude-feishu-bridge setup` installs cc-connect, writes config, and runs Feishu QR onboarding.
- `configure <user_id>` locks the bot to a single Feishu user and starts the background daemon (launchd on macOS, systemd on Linux).
- Pre-configured `acceptEdits` mode with rolling progress cards in Feishu.
- CLI subcommands: `status`, `logs`, `restart`, `stop`, `start`, `config`, `uninstall`.
- `pre-publish-check.sh` leak scanner for credential and identity string detection.

### Security

- `Bash` tool intentionally omitted from default `allowed_tools` — must be opted in explicitly.
- `allow_from` / `admin_from` access control via `configure` step.
