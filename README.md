# 🍃 MavKa — Your Personal AI Assistant in Telegram

**One script. 5 minutes. Less than $1/month.**

MavKa is a self-hosted AI assistant that lives in your Telegram. It runs on your computer, uses cloud AI (DeepSeek V4 Flash), and costs almost nothing.

## Why MavKa?

| | ChatGPT Plus | MavKa |
|---|---|---|
| **Cost** | $20/month | ~$0.10/month |
| **Privacy** | Your data on OpenAI servers | Runs on YOUR computer |
| **Voice** | ✓ | ✓ (Whisper) |
| **Photos** | ✓ | ✓ (Gemini) |
| **Web Search** | ✓ | ✓ (Tavily) |
| **Memory** | Limited | Persistent wiki |
| **Customizable** | No | Full control |

## Quick Start

```bash
bash install.sh
```

The installer will ask you for:
1. **DeepSeek API Key** → [platform.deepseek.com](https://platform.deepseek.com/api_keys) (top up $2)
2. **Groq API Key** → [console.groq.com](https://console.groq.com/keys) (free)
3. **Gemini API Key** → [aistudio.google.com](https://aistudio.google.com/apikey) (free)
4. **Tavily API Key** → [app.tavily.com](https://app.tavily.com/home) (free tier)
5. **Telegram Bot Token** → [@BotFather](https://t.me/BotFather) (free)
6. **Your Telegram User ID** → [@userinfobot](https://t.me/userinfobot)
7. **Bot personality** → Choose or customize

That's it. Open Telegram, say hi to your bot. 🍃

## Supported Platforms

- **macOS** (Apple Silicon & Intel)
- **Linux** (x86_64, ARM — Ubuntu, Debian, Fedora, etc.)
- **Windows** (via WSL2)

## Features

- 💬 **Chat** — Smart conversations powered by DeepSeek V4 Flash
- 🎤 **Voice** — Send voice messages, get text replies (Groq Whisper)
- 📷 **Photos** — Send photos for analysis (Gemini Vision)
- 🔍 **Search** — Real-time web search (Tavily + DuckDuckGo)
- 🧠 **Memory** — Persistent memory that survives restarts
- 🎭 **Personality** — Fully customizable (assistant, chef, coach, tutor...)
- 🔄 **Auto-start** — Survives reboots (launchd on Mac, systemd on Linux)

## Commands

```bash
# View logs
tail -f ~/mavka-bot/mavka.log

# Attach to console
screen -r mavka

# Restart
bash ~/mavka-bot/launch.sh

# Apply patches (after Pi Agent update)
bash ~/mavka-bot/patch.sh
```

## Architecture

```
You (Telegram) → Telegram Bot API → Pi Agent (your computer) → DeepSeek API (cloud)
```

Your computer is just a relay. The AI brain is in the cloud (DeepSeek), costing $0.14 per million tokens. Average user spends $0.10-0.50/month.

## Cost Breakdown

| Service | Cost |
|---|---|
| DeepSeek V4 Flash | $0.14/1M tokens (~$0.10-0.50/mo) |
| Groq Whisper | Free (8h/day) |
| Gemini Vision | Free tier |
| Tavily Search | Free tier (1000 searches/mo) |
| **Total** | **~$0.10-0.50/month** |

## License

MIT — do whatever you want with it.

---

Made with 💚 by [Atlas ✨](https://github.com/atlas)
