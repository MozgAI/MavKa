<p align="center">
  <img src="social-preview.png" alt="MavKa" width="640">
</p>

<h3 align="center">Your own AI. In Telegram. On your machine. For almost nothing.</h3>

<p align="center">
  <a href="#install"><strong>Install</strong></a> ·
  <a href="#two-products-in-one">What it does</a> ·
  <a href="#the-real-cost">Cost</a> ·
  <a href="#privacy--data">Privacy</a> ·
  <a href="SECURITY.md">Security</a>
</p>

---

## The Math That Broke My Brain

I was about to drop **$5,000** on a server to run local AI models. Then DeepSeek shipped V4 Flash — a **248B parameter** model at **$0.14 per million tokens**.

That $5,000 server couldn't physically run a 248B model. And the smaller one I'd settle for? The money I'd spend on hardware would cover **10 years** of Flash usage on the API.

Hardware depreciates monthly. Cloud models get better weekly. New providers launch, prices drop, you swap brains anytime.

So I stopped buying servers and built **MavKa** — a one-line installer that drops a full AI assistant into your Telegram, powered by absurdly cheap cloud models.

## Two Products in One

Most AI tools force a choice: a **chat app** on your phone, or a **coding agent** on your PC. MavKa is both.

**On your phone** — ChatGPT in Telegram. Voice notes, photo analysis, web search, persistent memory. No app to install. Open Telegram, talk to your AI.

**On your PC** — a local agent built on **Pi Agent** (the open-source engine behind tools like Claude Code / OpenClaw). Full file access, shell, computer use — same brain, same memory, same conversation as your phone.

One install. Two superpowers. **$2/month.**

## ChatGPT Plus is $20/month. MavKa is $2.

| | ChatGPT Plus | MavKa |
|---|---|---|
| **Casual chat** | $20/mo | **~$2/mo** |
| **Heavy coding** | $20/mo (with limits) | ~$30/mo (no limits, cheaper per token) |
| **Voice in** | Yes | Yes (Groq Whisper) |
| **Vision** | Yes | Yes (Gemini) |
| **Web Search** | Yes | Yes (Tavily) |
| **Memory** | Limited, opaque | **Persistent, you own it** |
| **Personality** | Vendor-controlled | **Yours to shape** |
| **Vendor lock-in** | Stuck with OpenAI | **Swap providers anytime** |
| **Where data goes** | OpenAI servers | API providers you choose, **keys you own** |

## Install

### Safe install (recommended)

Read the script first. Run it second.

```bash
git clone https://github.com/MozgAI/mavka.git
cd mavka
less install.sh        # read what it does
bash install.sh
```

### One-liner (for the brave)

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

### What the installer asks for

**Required:**
- **DeepSeek API Key** → [platform.deepseek.com](https://platform.deepseek.com/api_keys) (top up $2)
- **Telegram Bot Token** → [@BotFather](https://t.me/BotFather) (free)
- **Your Telegram User ID** → [@userinfobot](https://t.me/userinfobot) (free)

**Optional (skip to enable later):**
- **Groq Key** → voice transcription, free 8h/day
- **Gemini Key** → photo analysis, free tier
- **Tavily Key** → web search, free 1000/mo

After install: open Telegram, message your bot. Done.

### Uninstall

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.sh)
```

Removes the bot, autostart, local config. **Doesn't revoke API keys** — do that yourself on each provider.

## Privacy & Data

Let's be honest. MavKa is "self-hosted" but the AI itself runs in the cloud. Here's exactly what leaves your machine:

| Data | Goes to |
|---|---|
| Text messages | DeepSeek API |
| Voice notes | Groq API (transcribed, then text → DeepSeek) |
| Photos | Google AI Studio (Gemini) |
| Web search queries | Tavily API |
| Telegram messages | Telegram Bot API |

**What stays local:** your API keys, bot config, persistent memory, personality preset, conversation cache.

**What does NOT stay local:** the actual content of every message you send — by design.

If you need air-gapped privacy, MavKa is the wrong tool. Run llama.cpp with a local model instead.

The honest pitch isn't "private," it's: **you own the keys, you pick the providers, and you can swap them anytime.** OpenAI can't do that. Anthropic can't do that. You can.

See [SECURITY.md](SECURITY.md) for full details on data flow, key storage, and disclosure policy.

## The Real Cost

| Service | Pricing |
|---|---|
| DeepSeek V4 Flash (248B) | $0.14 per 1M tokens |
| Groq Whisper | Free (8h/day) |
| Gemini Vision | Free tier |
| Tavily Search | Free tier (1000/mo) |
| **Casual daily chat** | **~$2/month** |
| **Heavy coding use** | **~$30/month** |

Numbers are real measurements, not marketing. Your usage may differ — check your DeepSeek dashboard.

## How It Works

```
You (Telegram)
    ↓
Telegram Bot API
    ↓
Pi Agent (your machine)  ←  pi-telegram extension
    ↓
DeepSeek API (cloud)     ←  Groq, Gemini, Tavily for tools
```

Your computer runs a lightweight Node.js process. The heavy thinking happens in the cloud. Your data, memory, and config stay local. The AI brain is rented per token.

## Platforms

- **macOS** — Apple Silicon & Intel
- **Linux** — Ubuntu, Debian, Fedora, Arch, ARM
- **Windows** — via WSL2

## Daily Commands

```bash
tail -f ~/mavka-bot/mavka.log      # logs
tmux attach -t mavka               # attach to console (Ctrl+b d to detach)
bash ~/mavka-bot/launch.sh         # restart
```

## Why I Built This

I spent **half a day** manually setting up this same agent for my brother. SSH, configs, dependencies, Pi Agent patches, launchd plist. Hours.

Then it hit me: if a developer needs half a day, a normal person has zero chance.

MavKa is the fix. One command. Five minutes. Done.

## Status

Early days. **Two days old**, two contributors, tested on macOS and Arch Linux. Use at your own risk, file issues, send PRs.

## License

[MIT](LICENSE) — do whatever you want with it.

---

<p align="center"><b>Stop renting AI you don't own.</b></p>
