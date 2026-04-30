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
launchctl unload ~/Library/LaunchAgents/ai.mavka.bot.plist 2>/dev/null    # macOS
systemctl --user disable --now mavka 2>/dev/null                          # Linux

# Remove files
rm -rf ~/mavka-bot
rm -rf ~/.pi/agent
rm -f ~/Library/LaunchAgents/ai.mavka.bot.plist
rm -f ~/.config/systemd/user/mavka.service
```

After this, **revoke API keys on the provider websites** (DeepSeek, Groq, Google AI Studio, Tavily, BotFather). The local copy is gone but the keys themselves still work until revoked.

## Reporting vulnerabilities

Found something? Email **lytvynca@gmail.com** with subject `[MavKa Security]`.

Please don't open public issues for vulnerabilities — give me 7 days to fix before disclosure.

## What MavKa is NOT

- Not audited. This is a one-person side project.
- Not enterprise-ready. Don't deploy this for your company.
- Not a sandbox. Pi Agent has computer-use tools — it can read/write files in your home directory and run shell commands. Treat it like ssh access.
- Not a replacement for production-grade chatbots. Use it for personal use.
