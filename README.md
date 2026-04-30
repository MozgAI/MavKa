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

<h2 align="center">The ChatGPT killer that fits in one bash command.</h2>

<h3 align="center">Your own AI. In Telegram. On your machine. For the price of a coffee per month.</h3>

<p align="center">

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

</p>

<p align="center">
  <sub>macOS · Linux · 5 minutes · ~$2/month · 5 AI providers · open source</sub>
</p>

<p align="center">
  <a href="#why-mavka-kills-chatgpt-plus">Why it kills ChatGPT</a> ·
  <a href="#the-math-that-broke-my-brain">The math</a> ·
  <a href="#install">Install</a> ·
  <a href="#the-real-cost">Cost</a> ·
  <a href="#privacy--data">Privacy</a> ·
  <a href="SECURITY.md">Security</a>
</p>

---

## The Math That Broke My Brain

I was about to drop **$5,000–$10,000** on a workstation to run local AI models at home. The plan: a beefy GPU rig, MLX, llama.cpp, the whole stack.

Then DeepSeek shipped **V4 Flash** — a **248-billion-parameter** model at **$0.14 per million tokens**.

Read that price again.

A $10,000 home server **cannot physically run a 248B model.** I'd be stuck with something half the size, half the quality. Meanwhile, the money I'd spend on hardware would cover **10 years** of DeepSeek Flash usage on the API. **Ten years.**

Hardware depreciates monthly. Cloud frontier models get smarter weekly. New providers launch, prices keep dropping, and you can switch brains anytime — no lock-in.

So I stopped buying servers and built **MavKa** — a one-line installer that drops a full AI assistant into your Telegram, powered by these absurdly cheap cloud models. Five minutes. Two dollars. Done.

> **The lifehack of 2026: don't pay for ChatGPT Plus. Don't buy a $10,000 server. Pay $2 to DeepSeek and keep the change.**

## Why MavKa Kills ChatGPT Plus

| | ChatGPT Plus | **MavKa** |
|---|---|---|
| **Price** | $20/month | **~$2/month** |
| **Brain** | One model, take it or leave it | **5 providers**, swap anytime |
| **Where you use it** | Their app, their UI, their rules | **Telegram + your terminal** |
| **Voice in** | Yes | Yes (Groq Whisper) |
| **Vision** | Yes | Yes (Gemini) |
| **Web Search** | Yes | Yes (Tavily) |
| **Memory** | Black box, theirs | **Persistent wiki, yours** |
| **Personality** | Vendor-controlled | **You shape it. Chef? Coach? Tutor? Yes.** |
| **Computer use (read/write files, run commands)** | No | **Yes — Pi Agent under the hood** |
| **Vendor lock-in** | Stuck with OpenAI | **Switch to Claude / DeepSeek / Kimi / Groq in 30 seconds** |
| **Where data goes** | OpenAI servers, period | **API providers you choose, keys you own** |
| **Open source** | No | **Yes (MIT)** |
| **Self-hostable** | No | **Yes — runs on your machine** |

OpenAI can't switch you to Anthropic. Anthropic can't put themselves on your phone. Neither can put a real coding agent on your laptop with the same brain that just answered your voice note.

**MavKa is one install. Two superpowers. Five providers. Zero lock-in.**

## Two Products in One

Most AI tools force a choice: a **chat app** on your phone, or a **coding agent** on your PC. MavKa is both — sharing the same brain, the same memory, the same conversation.

### 📱 On your phone — ChatGPT in Telegram
Voice notes, photo analysis, web search, persistent memory. No app to install. Open Telegram, talk to your AI. Same chat works on your phone, tablet, watch, anywhere Telegram runs.

### 💻 On your PC — coding agent like Claude Code
Built on **Pi Agent** (the open-source engine behind Claude Code, OpenClaw and similar tools). Full file access, shell, computer use. Ask the bot in Telegram to refactor a file on your laptop — it just does it.

**One install. Two superpowers. ~$2/month.**

## Pick Your Brain

MavKa is **provider-agnostic**. Choose at install time, swap anytime by re-running the installer:

| Provider | Why pick it | Cost |
|---|---|---|
| **DeepSeek** V4 Flash | 248B parameters at $0.14/M tokens — the lifehack. *(recommended)* | **~$2/mo** |
| **ChatGPT** GPT-4o-mini | Mainstream OpenAI quality, familiar API | ~$5/mo |
| **Opus** Claude 4.7 | Anthropic's flagship — smartest model on the market | ~$30/mo |
| **Kimi 2.6** Moonshot | Long-context (128k+), strong on code | ~$3/mo |
| **Groq** Llama 3.3 70B | Free tier with daily limits, fastest inference | **$0** |

Why DeepSeek is the recommendation: **no other provider gets you a 248B model anywhere near $0.14 per million tokens.** It's a generational price-to-quality leap. The other four are there because nobody likes lock-in.

## Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

Prefer to **read the script before running it** (recommended for any `curl | bash`)?

```bash
git clone https://github.com/MozgAI/mavka.git
cd mavka
less install.sh
bash install.sh
```

### What the installer asks for (10 steps, ~5 minutes)

**Required:**
- **AI Provider** — DeepSeek / ChatGPT / Opus / Kimi / Groq (one click)
- **API key** for the provider you picked
- **Telegram Bot Token** → [@BotFather](https://t.me/BotFather) (free)
- **Your Telegram User ID** → [@userinfobot](https://t.me/userinfobot) (free)

**Optional** (skip to enable later):
- **Groq Key** → voice transcription via Whisper, free 8h/day
- **Gemini Key** → photo analysis, free tier
- **Tavily Key** → web search, free 1000/month

After step 3, MavKa's own AI takes over and walks you through the rest **conversationally** — in your language, on the same screen. No googling, no docs.

After install: open Telegram, message your bot. Done.

### Uninstall

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.sh)
```

Removes the bot, autostart, local config. **Doesn't revoke API keys** — do that yourself on each provider.

## Privacy & Data

Let's be honest. MavKa is "self-hosted" but the AI brain itself runs in the cloud. Here's exactly what leaves your machine:

| Data | Goes to |
|---|---|
| Text messages | The AI provider you picked (DeepSeek / OpenAI / Anthropic / Moonshot / Groq) |
| Voice notes | Groq API (Whisper transcribes → text → your AI) |
| Photos | Google AI Studio (Gemini) |
| Web search queries | Tavily API |
| Telegram messages | Telegram Bot API |

**What stays local:** your API keys, bot config, persistent memory, personality preset, conversation cache.

**What does NOT stay local:** the actual content of every message you send — by design. That's the trade-off for not running a 248B model on your laptop.

If you need air-gapped privacy, MavKa is the wrong tool. Run llama.cpp with a local model instead.

The honest pitch isn't "private," it's: **you own the keys, you pick the providers, and you can swap them anytime.** OpenAI can't do that. Anthropic can't do that. You can.

See [SECURITY.md](SECURITY.md) for full details on data flow, key storage, and how to nuke everything.

## The Real Cost

| Provider | Casual chat | Heavy coding |
|---|---|---|
| **DeepSeek** V4 Flash *(recommended)* | **~$2/mo** | ~$30/mo |
| **ChatGPT** GPT-4o-mini | ~$5/mo | ~$60/mo |
| **Opus** Claude 4.7 | ~$30/mo | ~$200+/mo |
| **Kimi 2.6** Moonshot | ~$3/mo | ~$40/mo |
| **Groq** Llama 3.3 70B | **$0** (free tier) | hits daily limits |

Tools layered on top:

| Service | Pricing |
|---|---|
| Groq Whisper (voice) | Free (8h/day) |
| Gemini Vision (photos) | Free tier |
| Tavily Search | Free tier (1000/mo) |

Numbers are real measurements with DeepSeek across daily-driver use. Your usage may differ — check your provider's dashboard.

## How It Works

```
You (Telegram)
    ↓
Telegram Bot API
    ↓
Pi Agent (your machine)  ←  pi-telegram extension
    ↓
Your AI provider (cloud) ←  Groq + Gemini + Tavily for tools
```

Your computer runs a lightweight Node.js process. The heavy thinking happens in whichever cloud you picked. Your data, memory, and config stay local. **The brain is rented per token — switch providers anytime by re-running the installer.**

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

MavKa is the fix. **One command. Five minutes. Done.** And while I was at it, I made sure no provider can ever lock you in.

## Status

Early days. Tested on macOS (Apple Silicon) and Arch Linux. Use at your own risk, file issues, send PRs.

## License

[MIT](LICENSE) — do whatever you want with it.

---

<p align="center"><b>Stop paying $20/month for AI you don't own.</b></p>
<p align="center"><sub>Made with 🍃 — open source forever.</sub></p>
