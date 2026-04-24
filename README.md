# claude-feishu-bridge

Drive [Claude Code](https://claude.com/claude-code) from your Feishu / Lark DMs. An opinionated starter on top of [cc-connect](https://github.com/chenhg5/cc-connect) that gets you from zero to a running bot in about five minutes.

## ⚠️ Read this first

This bridge lets messages sent to a chat bot **execute code, edit files, and run shell commands on your machine**. Install it only on a device you personally own, and keep the bot locked to your own user ID via `allow_from` (the setup script handles this for you). Do not share your `~/.cc-connect/config.toml` — it contains the app secret that, combined with the bot's `app_id`, gives full control of the bot.

## What you get

- Claude Code running on your Mac or Linux box, reachable via Feishu DM.
- Launchd (macOS) or systemd user-service (Linux) persistence — auto-starts on login, auto-restarts on crash.
- Pre-configured display defaults: intermediate tool calls roll into a single structured card instead of spamming the chat.
- `acceptEdits` mode + pre-approved read/edit/search tools, so routine tasks stop asking for permission mid-run. `Bash` is intentionally _not_ pre-approved — add it in `config.toml` if you trust all prompts fully.
- Locked-down by default: only your own user ID can talk to the bot.

## Prerequisites

- **macOS** or **Linux** (Windows not supported — cc-connect's daemon targets launchd and systemd).
- **Node.js ≥ 18** with `npm` on your PATH. `nvm`, `fnm`, or Homebrew all work.
- A **Feishu** (or Lark) account you can sign in with, with permission to create a custom app. The setup uses Feishu's QR onboarding — you do not need to click through the Open Platform console manually.

## Install

```bash
git clone https://github.com/jerrysoer/claude-feishu-bridge.git
cd claude-feishu-bridge
./bin/claude-feishu-bridge setup
```

The `setup` step will:

1. Install `cc-connect` globally via `npm` (if not already installed).
2. Write a config template to `~/.cc-connect/config.toml`, prompting for the absolute path where Claude Code should run.
3. Open a QR code in your terminal. Scan it with the Feishu mobile app — a bot is auto-created in your tenant and its credentials are written straight into the config.

## Lock down & start the daemon

The bot is not accessible yet — you still need to tell it who you are.

1. Open Feishu. Search for the bot that just appeared in your contacts (its name comes from the Feishu QR onboarding flow).
2. Send the bot: `/whoami`. It replies with a block containing your user ID — a string starting with `ou_`.
3. Copy that ID and run:

   ```bash
   ./bin/claude-feishu-bridge configure ou_YOUR_USER_ID_HERE
   ```

This injects `allow_from` and `admin_from`, then installs and starts the background daemon. After this, only your account can DM the bot, and only your account can run privileged commands like `/shell` and `/restart`.

## Smoke test

Back in Feishu, DM the bot something real:

```
list the files in work_dir
```

Within a few seconds you should see a rolling progress card, followed by the file listing. If it hangs or errors, see [docs/troubleshooting.md](docs/troubleshooting.md).

## Daily use

| Command | Effect |
|---|---|
| `./bin/claude-feishu-bridge status` | Show daemon state |
| `./bin/claude-feishu-bridge logs -f` | Tail the daemon log |
| `./bin/claude-feishu-bridge restart` | Restart after editing config |
| `./bin/claude-feishu-bridge config` | Open `~/.cc-connect/config.toml` in `$EDITOR` |
| `./bin/claude-feishu-bridge uninstall` | Remove the daemon and (optionally) the config |

In Feishu, the bot responds to built-in slash commands: `/help`, `/status`, `/new`, `/list`, `/switch`, `/mode`, `/model`, `/quiet`, `/compress`, `/memory`, `/cron`, and the admin-only `/shell`, `/dir`, `/restart`, `/upgrade`.

## Customization

All configuration is in `~/.cc-connect/config.toml`. The knobs you're most likely to touch:

- **`work_dir`** — the absolute path where Claude Code operates. Restart after changing.
- **`mode`** — `default` (ask for every tool), `acceptEdits` (default here; auto-approve edits), `plan` (plan only), `bypassPermissions` (auto-approve everything; careful).
- **`allowed_tools`** — tools that never prompt. The default includes common read/write tools but _not_ `Bash` (which would auto-approve arbitrary shell commands from chat). Add `"Bash"`, `"TodoWrite"`, `"Task"`, etc. as needed.
- **`progress_style`** — `card` (default here; rolling progress card), `compact` (single rolling message), or `legacy` (a message per tool call).

cc-connect supports a lot more than this starter exposes — multiple projects, multiple agents (Codex, Gemini, Cursor, etc.), cron jobs, heartbeats, voice messages, custom slash commands, cross-project relay. See the [upstream config reference](https://github.com/chenhg5/cc-connect/blob/main/config.example.toml) — everything there works in `~/.cc-connect/config.toml`.

## Uninstall

```bash
./bin/claude-feishu-bridge uninstall
```

This stops and removes the daemon, and asks before removing `~/.cc-connect/` (which contains your session history and config). To also remove the cc-connect binary: `npm uninstall -g cc-connect`.

## How it works

```
Feishu app  ──WebSocket──▶  cc-connect (local daemon)  ──stdio──▶  claude CLI
     ▲                              │                                   │
     └──────────── reply ───────────┴───────────── output ──────────────┘
```

- Feishu messages arrive over a persistent WebSocket the daemon opens to Feishu's Open Platform. No public IP or port-forwarding is needed.
- cc-connect spawns and supervises a `claude` process per session, feeding the user's message as a prompt and streaming output back to the chat.
- Everything runs on your machine. No traffic goes to any third party other than Feishu's API and the LLM provider Claude Code is configured to use.

## Third-party dependency

This project depends on [cc-connect](https://github.com/chenhg5/cc-connect), a third-party npm package that manages the WebSocket connection and process supervision. It is installed globally via `npm` during setup. Review its source before installing if your threat model requires it.

## Credits

- Built on [chenhg5/cc-connect](https://github.com/chenhg5/cc-connect) (MIT).
- Claude Code is by Anthropic.

## License

MIT — see [LICENSE](LICENSE).
