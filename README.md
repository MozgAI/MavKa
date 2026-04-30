<p align="center">
  <img src="social-preview.png" alt="MavKa" width="640">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/MozgAI/MavKa?color=50fa7b" alt="MIT License"></a>
  <a href="https://github.com/MozgAI/MavKa/stargazers"><img src="https://img.shields.io/github/stars/MozgAI/MavKa?color=8be9fd" alt="Stars"></a>
  <img src="https://img.shields.io/badge/macOS-Apple_Silicon%20%7C%20Intel-c0c0d0" alt="macOS">
  <img src="https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Arch%20%7C%20Debian-c0c0d0" alt="Linux">
  <img src="https://img.shields.io/badge/install-5_min-50fa7b" alt="Install time">
  <img src="https://img.shields.io/badge/cost-~%242%2Fmonth-bd93f9" alt="Cost">
</p>

<h3 align="center">Your own AI. In Telegram. On your machine. For almost nothing.</h3>

<p align="center">

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

</p>

<p align="center">
  <sub>macOS · Linux · 5 minutes · ~$2/month</sub>
</p>

<p align="center">
  <a href="#install"><strong>Install details</strong></a> ·
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

The one-liner is at the top of this README. If you'd rather **read the script before running it** (recommended for any `curl | bash`):

```bash
git clone https://github.com/MozgAI/mavka.git
cd mavka
less install.sh
bash install.sh
```

### What the installer asks for

**Required:**
- **AI Provider** — pick one of:
  - **DeepSeek** → [platform.deepseek.com](https://platform.deepseek.com) — cheapest, ~$2/mo *(recommended)*
  - **ChatGPT** (OpenAI) → [platform.openai.com](https://platform.openai.com) — GPT-4o-mini
  - **Opus** (Anthropic) → [console.anthropic.com](https://console.anthropic.com) — Claude Opus 4.7
  - **Kimi 2.6** (Moonshot) → [platform.moonshot.ai](https://platform.moonshot.ai) — long context
  - **Groq** → [console.groq.com](https://console.groq.com) — Llama 3.3 70B, free tier with limits
- **Telegram Bot Token** → [@BotFather](https://t.me/BotFather) (free)
- **Your Telegram User ID** → [@userinfobot](https://t.me/userinfobot) (free)

**Optional (skip to enable later):**
- **Groq Key** → voice transcription via Whisper, free 8h/day
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
| Text messages | Your chosen AI provider (DeepSeek / OpenAI / Anthropic / Groq) |
| Voice notes | Groq API (transcribed via Whisper, then text → your AI) |
| Photos | Google AI Studio (Gemini) |
| Web search queries | Tavily API |
| Telegram messages | Telegram Bot API |

**What stays local:** your API keys, bot config, persistent memory, personality preset, conversation cache.

**What does NOT stay local:** the actual content of every message you send — by design.

If you need air-gapped privacy, MavKa is the wrong tool. Run llama.cpp with a local model instead.

The honest pitch isn't "private," it's: **you own the keys, you pick the providers, and you can swap them anytime.** OpenAI can't do that. Anthropic can't do that. You can.

See [SECURITY.md](SECURITY.md) for full details on data flow, key storage, and disclosure policy.

## The Real Cost

Depends on which provider you pick:

| Provider | Casual chat | Heavy coding |
|---|---|---|
| **DeepSeek** V4 Flash | ~$2/mo | ~$30/mo |
| **ChatGPT** GPT-4o-mini | ~$5/mo | ~$60/mo |
| **Opus** Claude 4.7 | ~$30/mo | ~$200+/mo |
| **Kimi 2.6** Moonshot | ~$3/mo | ~$40/mo |
| **Groq** Llama 3.3 70B | $0 (free tier) | hits daily limits |

Tools layered on top:

| Service | Pricing |
|---|---|
| Groq Whisper (voice) | Free (8h/day) |
| Gemini Vision (photos) | Free tier |
| Tavily Search | Free tier (1000/mo) |

Numbers are estimates from real measurements with DeepSeek. Your usage may differ — check your provider's dashboard.

## How It Works

```
You (Telegram)
    ↓
Telegram Bot API
    ↓
Pi Agent (your machine)  ←  pi-telegram extension
    ↓
Your AI provider (cloud) ←  Groq, Gemini, Tavily for tools
```

Pick your brain at install time: **DeepSeek**, **OpenAI**, **Anthropic**, or **Groq**. Your computer runs a lightweight Node.js process. The heavy thinking happens in the cloud. Your data, memory, and config stay local. The AI brain is rented per token — and you can switch providers anytime by re-running the installer.

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

Early days. Tested on macOS (Apple Silicon) and Arch Linux. Use at your own risk, file issues, send PRs.

## License

[MIT](LICENSE) — do whatever you want with it.

---

<p align="center"><b>Stop renting AI you don't own.</b></p>
