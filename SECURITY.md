# Security Policy

## What MavKa runs on your machine

MavKa is a thin local agent. It runs:

- **Pi Agent** (Node.js process) — orchestrates conversation, tool calls
- **pi-telegram extension** — bridges Telegram Bot API to Pi Agent
- A **tmux session** named `mavka` — keeps it alive across terminal closes
- An **autostart entry** — `launchd` plist on macOS, `systemd` user unit on Linux

That's it. No server, no open ports, no incoming connections.

## What data leaves your machine

MavKa is *self-hosted*, but the AI models live in the cloud. Be honest with yourself: when you message the bot, the text is sent to whichever cloud APIs you configured.

| Data | Goes to | Why |
|---|---|---|
| Text messages | DeepSeek API | LLM inference |
| Voice notes | Groq API | Speech-to-text (Whisper) |
| Photos | Google AI Studio | Vision (Gemini) |
| Web search queries | Tavily API | Real-time search |
| Telegram messages | Telegram Bot API | Message routing |

**What stays local:** your API keys, your bot config, your chat history (only what Pi Agent caches), your memory wiki, your personality preset.

**What does NOT stay local:** the actual content of every message, voice note, and photo you send — by design. That's the trade-off for not running a 248B model on your laptop.

If you need full air-gapped privacy, MavKa is the wrong tool. Run `llama.cpp` with a local model instead.

## Where API keys are stored

After install, your keys live in plain text in these files:

```
~/mavka-bot/start.sh           # exports API keys as env vars
~/.pi/agent/auth.json          # Pi Agent provider auth (DeepSeek)
~/.pi/agent/telegram.json      # Telegram bot token + allowed user IDs
```

These files are owned by your user, mode 0600. They are **not** encrypted at rest. If your machine is compromised, your keys are exposed.

**Recommendations:**
- Use API keys with minimum required scope
- Set spending limits on DeepSeek (top up only $2-5 at a time)
- Rotate keys if you suspect compromise (`uninstall.sh` removes local copies, but you must revoke on the provider side)

## How to uninstall completely

Run the uninstaller from the repo:

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.sh)
```

Or manually:

```bash
# Stop the bot
tmux kill-session -t mavka 2>/dev/null

# Disable autostart
launchctl unload ~/Library/LaunchAgents/com.mavka.bot.plist 2>/dev/null    # macOS
systemctl --user disable --now mavka 2>/dev/null                          # Linux

# Remove files
rm -rf ~/mavka-bot
rm -rf ~/.pi/agent
rm -f ~/Library/LaunchAgents/com.mavka.bot.plist
rm -f ~/.config/systemd/user/mavka.service
```

After this, **revoke API keys on the provider websites** (DeepSeek, Groq, Google AI Studio, Tavily, BotFather). The local copy is gone but the keys themselves still work until revoked.

## Reporting vulnerabilities

Found something? Email **lytvynca@gmail.com** with subject `[MavKa Security]`.

Please don't open public issues for vulnerabilities — give me 7 days to fix before disclosure.

## Pi Agent's trust model (important)

MavKa is built on [Pi Coding Agent](https://github.com/badlogic/pi-mono). Pi is intentionally a "YOLO" agent — the author has [stated explicitly](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) that there are no permission popups, no per-action confirmations, no allow-lists in the core. When the LLM says "run this shell command", Pi runs it.

**Treat MavKa like SSH access to your user account.** It can:
- Read any file your user can read.
- Write or delete files in your home directory.
- Run shell commands as you (no sudo, but everything else).
- Make outbound network requests.

### What MavKa does to mitigate

The installer enables Pi's [sandbox extension](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent/examples/extensions/sandbox) by default on macOS and Linux. It uses:
- **macOS:** `sandbox-exec` (built into the OS).
- **Linux:** `bubblewrap` (auto-installed via apt/pacman/dnf if missing).
- **Windows:** **no sandbox available** — Windows beta has no equivalent yet.

Default deny-list (in `~/.pi/agent/extensions/sandbox.json`):
```
denyRead:  ~/.ssh ~/.aws ~/.gnupg ~/mavka-bot/start.sh
denyWrite: .env .env.* *.pem *.key
allowWrite: . /tmp ~/mavka-bot
```

**Critical limitation:** the sandbox extension only intercepts the `bash` tool. The built-in `read`, `write`, and `edit` tools still have full filesystem access through Node — they're not sandboxed. So Pi can still read your `~/.ssh/id_rsa` via the `read` tool even with sandbox enabled.

### What MavKa does NOT do

- No per-command confirmation prompts (that fights Pi's design).
- No Docker/VM isolation.
- No code review of LLM-suggested actions before they execute.
- No sandbox at all on Windows (beta).

### If you want stronger isolation

- Run MavKa in a dedicated VM (UTM/Parallels/VirtualBox/multipass).
- Run it under a separate, low-privilege user account.
- Don't install it on a machine with credentials you can't afford to lose (don't put MavKa next to your production SSH keys).
- Wait for a future version with stronger sandboxing — issue trackers welcome.

## What MavKa is NOT

- Not audited. One-person side project.
- Not enterprise-ready. Don't deploy this for your company.
- Not a sandbox in any strong sense — see "Pi Agent's trust model" above.
- Not a replacement for production-grade chatbots. Use it for personal projects.
