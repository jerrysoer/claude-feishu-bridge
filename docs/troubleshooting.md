# Troubleshooting

## The bot doesn't reply at all

Check the daemon:

```bash
claude-feishu-bridge status
```

If it shows `Stopped`, start it:

```bash
claude-feishu-bridge start
```

If it shows `Running` but the bot is silent, tail the logs while you send a test message:

```bash
claude-feishu-bridge logs -f
```

You should see a line containing `feishu` and `connected` near the top. If you see repeated `retrying request with fresh tenant access token` warnings, your `app_id` / `app_secret` may be wrong — re-run `claude-feishu-bridge setup` to redo the QR flow.

## The bot replies but I can't talk to it

You probably hit an `allow_from` mismatch. DM the bot `/whoami` — if it responds, good. If the response user_id doesn't match what you set during `configure`, re-run:

```bash
claude-feishu-bridge configure ou_YOUR_ACTUAL_USER_ID
```

## Permission prompts for every tool call

Edit `allowed_tools` in `~/.cc-connect/config.toml` to pre-approve specific tools:

```bash
claude-feishu-bridge config
# add the tool name (e.g. "TodoWrite") to allowed_tools
claude-feishu-bridge restart
```

To auto-approve *everything*, set `mode = "bypassPermissions"`. Only do this on a machine you own — the bot can run any shell command without asking.

## "work_dir does not exist"

The `work_dir` you entered during setup must be an absolute path to an existing directory. Edit and restart:

```bash
claude-feishu-bridge config
claude-feishu-bridge restart
```

## "could not find bot in Feishu"

After QR onboarding, it can take a few seconds for the bot to appear in your contacts. If it still doesn't show up:

- Search by the name displayed on the last screen of the QR flow.
- Check the Workplace (工作台) tab.
- Visit https://open.feishu.cn/app in a browser — your newly-created app should be listed there.

## Daemon won't start after editing config

Syntax errors in `config.toml` make the daemon exit immediately. Check the log:

```bash
claude-feishu-bridge logs -n 50
```

Look for `config` / `parse` errors. A common one is TOML strings missing their closing quote after a sed edit gone wrong.

## Uninstalling cleanly

```bash
claude-feishu-bridge uninstall
```

will walk through removing the daemon, `~/.cc-connect/`, and optionally the `cc-connect` binary itself.

## Still stuck?

- Upstream daemon docs: `cc-connect daemon --help`
- Upstream config reference: https://github.com/chenhg5/cc-connect/blob/main/config.example.toml
- Upstream issues: https://github.com/chenhg5/cc-connect/issues
