<p align="center">
  <img src="social-preview.png" alt="MavKa" width="640">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/MozgAI/MavKa?color=50fa7b" alt="MIT License"></a>
  <a href="https://github.com/MozgAI/MavKa/stargazers"><img src="https://img.shields.io/github/stars/MozgAI/MavKa?color=8be9fd" alt="Stars"></a>
  <img src="https://img.shields.io/badge/macOS-Apple_Silicon%20%7C%20Intel-c0c0d0" alt="macOS">
  <img src="https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Arch%20%7C%20Debian-c0c0d0" alt="Linux">
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011%20(beta)-ffb86c" alt="Windows beta">
  <img src="https://img.shields.io/badge/install-5_min-50fa7b" alt="Install time">
  <img src="https://img.shields.io/badge/cost-~%242%2Fmonth-bd93f9" alt="Cost">
</p>

<h2 align="center">The ChatGPT killer. The OpenClaw killer.<br>The easiest way into vibecoding ever shipped.</h2>

<h3 align="center">Your own AI. In Telegram. Coding agent on your laptop.<br>One install. ~$2/month on DeepSeek. No limits. No lock-in.</h3>

<p align="center">

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

</p>

<p align="center">
  <sub>macOS · Linux · Windows · 5 minutes · ~$2/month on DeepSeek · 5 AI providers · hands-free voice · AI installs itself · MIT</sub>
</p>

<p align="center">
  <a href="#why-mavka-kills-chatgpt-plus">vs ChatGPT</a> ·
  <a href="#vibecoding-the-easy-way">Vibecoding</a> ·
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

A $10,000 home server **cannot physically run a 248B model.** I'd be stuck with something half the size, half the quality. Meanwhile, the same money on the API covers **years** of heavy daily use — and the hardware would be obsolete long before that.

Hardware depreciates monthly. Cloud frontier models get smarter weekly. New providers launch, prices keep dropping, and you can switch brains anytime — no lock-in.

So I stopped buying servers and built **MavKa** — a one-line installer that drops a full AI assistant into your Telegram, powered by these absurdly cheap cloud models. Five minutes. ~$2 a month on DeepSeek for an active chat companion. Done.

> **The lifehack of 2026: don't pay $20/month for ChatGPT Plus. Don't buy a $10,000 server. Top up $2 on DeepSeek and use it for a month.**

## Why MavKa Kills ChatGPT Plus

| | ChatGPT Plus | **MavKa** |
|---|---|---|
| **Price** | $20/month | **~$2/month** (active chat use, on DeepSeek) |
| **Brain** | One model, take it or leave it | **5 providers**, swap anytime |
| **Where you use it** | Their app, their UI, their rules | **Telegram + your terminal** |
| **Voice in** | Yes | Yes (Groq Whisper, free) |
| **Voice out (TTS)** | App only | **Yes — replies as voice notes (free Edge TTS)** |
| **Vision** | Yes | Yes (Gemini) |
| **Web Search** | Yes | Yes (Tavily) |
| **Memory** | Black box, theirs | **Persistent wiki, yours** |
| **Personality** | Vendor-controlled | **You shape it. Chef? Coach? Tutor? Yes.** |
| **Computer use (read/write files, run commands)** | No | **Yes — Pi Agent under the hood** |
| **Vendor lock-in** | Stuck with OpenAI | **Switch to Claude / DeepSeek / Kimi / Groq in 30 seconds** |
| **Where data goes** | OpenAI servers, period | **API providers you choose, keys you own** |
| **Open source** | No | **Yes (MIT)** |
| **Self-hostable** | No | **Yes — runs on your machine** |
| **Setup difficulty** | Sign up → done | **One bash command. AI walks you through the rest.** |

OpenAI can't switch you to Anthropic. Anthropic can't put themselves on your phone. Neither can put a real coding agent on your laptop with the same brain that just answered your voice note.

**MavKa is one install. Two superpowers. Five providers. Zero lock-in.**

### Also better than your favorite coding tools

| | Cursor | Claude Code / OpenClaw | **MavKa** |
|---|---|---|---|
| Price | $20/mo | Pay-per-token | **~$5–10/mo heavy coding (DeepSeek)** |
| Where you talk to it | IDE only | Terminal only | **Telegram + terminal** |
| Voice control (in + out) | No | No | **Yes — fully hands-free** |
| Photo / screenshot understanding | No | No | **Yes** |
| Switch model providers | Limited | Limited | **5 providers, anytime** |
| Memory across sessions | Limited | Limited | **Persistent wiki** |
| Open source | No | No | **Yes (MIT)** |
| Install help | None — read docs | None — read docs | **AI installs itself, in your language** |

## Two Products in One

Most AI tools force a choice: a **chat app** on your phone, or a **coding agent** on your PC. MavKa is both — sharing the same brain, the same memory, the same conversation.

### 📱 On your phone — ChatGPT in Telegram
Voice in, voice out, photo analysis, web search, persistent memory. **Talk to MavKa hands-free** — send a voice note, get a voice note back. Driving, cooking, working out — keep going, MavKa speaks. No app to install. Same chat works on your phone, tablet, watch, anywhere Telegram runs.

> Voice in via **Groq Whisper** (free 8h/day). Voice out via **Microsoft Edge TTS** (free, no key). **Hands-free conversation costs zero on top of the LLM tokens.**

### 💻 On your PC — coding agent like Claude Code
Built on **Pi Agent** (the open-source engine behind Claude Code, OpenClaw and similar tools). Full file access, shell, computer use. Ask MavKa in Telegram to refactor a file on your laptop — it just does it.

**One install. Two superpowers. Pennies a month.**

## Even Your Mom Can Install It

Here's the dirty secret of every "self-hosted AI agent" out there: **you need another AI to install it.** People literally open ChatGPT or Claude Code in another tab and ask *"how do I configure this auth.json"* — because doing it by hand is fragile, error-prone, and the docs are written for engineers.

**MavKa is the first AI agent where the AI installs itself.** After you give it the API key, the installer hands you over to MavKa's own brain — running live, in your terminal, in your language — and walks you through the rest of setup conversationally:

- *"Я не могу найти этот ключ"* → it explains where to click, in Russian.
- *"What does Tavily do? Do I need it?"* → straight answer, then asks if you want to skip.
- *"можем сделать это потом"* → done, on to the next step.

No second tool. No copy-pasting questions to ChatGPT. No engineer in the family.

> **Slogan: "Even your mom can install it."** And we mean it.

## Who Is MavKa For?

MavKa isn't just for developers. It's a **personal AI agent with a brain, internet access, and your memory** — useful for almost everyone who has a phone.

### 👨‍💻 Developers & vibecoders
Voice-driven coding, repo refactors, debugging, commits, deployments — all from Telegram, all running on your laptop. See [Vibecoding the Easy Way](#vibecoding-the-easy-way) below.

### 🎓 Students & learners
Explain a calculus problem with a photo of the page. Summarize a 60-page PDF. Practice a foreign language out loud (voice in, voice out). Get tutored on any topic — MavKa remembers what you already know.

### 🏠 At home — recipes, lifehacks, household (hands-free)
Hands wet, dough on fingers, baby on hip — talk to MavKa, get voice answers back.
*"What can I cook with these?"* — photo of your fridge.
*"Best way to remove red wine from white shirt?"* — voice while doing laundry.
*"Make me a 7-day meal plan, $80 budget, two people"* — done.
*"Read this label, is it gluten-free?"* — photo of the package.

### 🥗 Diet, fitness, calories
Send a photo of your plate — MavKa estimates calories and macros. Discuss meal plans, training programs, swap exercises. Track progress in persistent memory across weeks.

### 💪 At the gym (hands-free)
Hold up your phone, say *"I'm at the gym, dumbbells busy. Build me a chest workout with just barbells."* — MavKa replies as a voice note. Keep training. No screen, no typing.
*"How do I do a Romanian deadlift correctly?"* — voice in, voice out. Step-by-step in your earbuds.

### 💄 Beauty, skincare, style
*"Read these ingredients — anything I should avoid for sensitive skin?"*
*"Outfit advice for a job interview, budget $200"* — describe what you have, MavKa picks combinations.

### 📊 Personal finance & bookkeeping
Photograph receipts → MavKa categorizes them. Build a personal budget. Walk through tax basics. Ask about a contract clause before you sign.

### 🩺 Health curiosity (not medical advice)
*"What does this rash look like?"* — photo + symptoms → general info + advice to see a doctor.
*"My BP reads 140/90 — should I be worried?"* — context, what to track.
**MavKa is not a doctor. For anything serious, see a real one.** It's a smart sidekick for tracking and curiosity, not a replacement for medical care.

### 🌍 Travel, languages, life admin
Translate a menu via photo. Get hidden-gem restaurant picks for a city you're visiting. Draft a polite cancellation email to your landlord. Plan a trip itinerary. Find that one website you visited last week.

### 🧠 Anything else that fits in a Telegram chat
Real-time web search via Tavily. Photo analysis via Gemini. Voice in via Whisper. Persistent memory that learns who you are — your kids' names, your allergies, your projects, your goals.

**MavKa is the agent you can ask anything. It has the internet, your camera, your voice, and a long memory. It's yours.**

## Vibecoding the Easy Way

You've heard the term — *vibecoding*: you describe the vibe, the AI writes the code, you review and ship. The problem is the on-ramp:

- **Cursor / Windsurf** — slick, but $20/month and another IDE to learn
- **Claude Code / OpenClaw** — powerful, but it's a CLI tool with a learning curve
- **GitHub Copilot** — autocomplete-tier, not a real agent
- **Local models** — slow on consumer hardware, model quality lags 6 months

MavKa is different: **the same AI that just answered your voice note in Telegram is sitting in your terminal, ready to read your repo, run tests, write commits, push branches.**

```
You (in bed):    "fix the auth bug we talked about yesterday"
MavKa (laptop):  reads ~/projects/api/auth.ts, finds the issue,
                 runs the failing test, patches it, runs again,
                 reports back in your Telegram with a diff
```

Same brain. Same memory. Same conversation. **One install, no IDE switch, no $20/month subscription.** The cheapest, lowest-friction entry into agentic coding that exists right now.

> **If you want to start vibecoding without paying $20/month for Cursor or fighting Claude Code's CLI — MavKa is the on-ramp.**

## Pick Your Brain

MavKa is **provider-agnostic**. Choose at install time, swap anytime by re-running the installer:

| Provider | Why pick it | Active chat-bot use (real) |
|---|---|---|
| **DeepSeek** V4 Flash | 248B parameters at $0.14/M tokens — the lifehack. *(recommended)* | **~$2/mo** |
| **ChatGPT** GPT-4o-mini | Mainstream OpenAI quality, familiar API | ~$5/mo |
| **Kimi 2.6** Moonshot | Long-context (262K), strong on code | ~$25–35/mo |
| **Opus** Claude 4.7 | Anthropic's flagship — smartest model on the market | ~$200–400/mo (no caching) |
| **Groq** Llama 3.3 70B | Free tier with daily limits, fastest inference | **$0** *(within free quota)* |

Why DeepSeek is the recommendation: **no other provider gets you a 248B model anywhere near $0.14 per million tokens.** It's a generational price-to-quality leap. Every other provider listed here is **at least 2–200× more expensive** for the same daily chat volume. The reason they're still in the menu: nobody likes lock-in, and some users have credits or strong preferences.

## Install

### macOS / Linux

```bash
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
```

### Windows (native PowerShell, no WSL) — **BETA**

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/MozgAI/mavka/main/install.ps1 | iex"
```

> ⚠️ **Windows support is currently in BETA.** Mac/Linux are battle-tested, Windows hasn't been deeply tested yet. Same flow, same providers, same AI-guided setup. Uses Git Bash (auto-installed via winget) for Pi Agent's shell — WSL not needed. Please file an issue if anything breaks.

### Prefer to read the script first? (recommended for any one-liner install)

```bash
# macOS / Linux
git clone https://github.com/MozgAI/mavka.git
cd mavka
less install.sh
bash install.sh
```

```powershell
# Windows
git clone https://github.com/MozgAI/mavka.git
cd mavka
notepad install.ps1
powershell -ExecutionPolicy Bypass -File install.ps1
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

After install: open Telegram, say hi to MavKa. Done.

### Uninstall

```bash
# macOS / Linux
bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.sh)
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.ps1 | iex"
```

Removes MavKa, autostart, local config. **Doesn't revoke API keys** — do that yourself on each provider.

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

## Trust Model — Read This Before Installing

MavKa runs **Pi Coding Agent** under the hood, and Pi is intentionally a "YOLO" agent — its author says so [openly](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/). It has no built-in permission popups, no per-action confirmations, no allow-lists. When the LLM says "run this shell command", Pi runs it.

**Treat MavKa like SSH access to your user account.** That means:

- It can read any file your user can read.
- It can write/delete files in your home directory.
- It can run shell commands as you (no `sudo`, but everything else).
- It can make outbound network requests.

**What MavKa does to mitigate this:**

- On macOS/Linux, the installer enables Pi's `@anthropic-ai/sandbox-runtime` extension by default. It deny-lists `~/.ssh`, `~/.aws`, `~/.gnupg`, and secret-looking paths (`*.pem`, `*.key`, `.env*`) for shell commands. It uses `sandbox-exec` on macOS, `bubblewrap` on Linux. **It does NOT sandbox the `read`/`write`/`edit` tools** — those still have full FS access through Node.
- API keys are stored in `~/.pi/agent/auth.json` mode 0600 (only your user can read).
- You can completely uninstall with `bash <(curl -sL .../uninstall.sh)` — and rotate API keys on each provider's site.

**What MavKa does NOT do:**

- No per-command confirmation prompts (that fights Pi's design).
- No Docker/VM isolation.
- No code review of LLM-suggested actions before they execute.

**If that's not your trust level**, don't install MavKa on a machine with credentials you can't afford to lose. Run it in a VM, or wait for a future version with stronger sandboxing. Be honest about who's getting SSH-equivalent access here: you, the LLM you picked, and (in theory) anyone who can compromise that LLM provider.

## The Real Cost — Honest Numbers

These are real costs at typical chat-bot use (~150–200K tokens/day total — the kind of person who actually uses MavKa daily for chat, voice, photos, web search, light coding).

| Provider | Active chat-bot use | Heavy coding |
|---|---|---|
| **DeepSeek** V4 Flash *(recommended)* | **~$2/mo** | ~$5–10/mo |
| **Groq** Llama 3.3 70B | **$0** *(within free tier; lighter chats only — limits hit fast on heavy days)* | ~$10–20/mo over free TPD |
| **ChatGPT** GPT-4o-mini | ~$5/mo | ~$15–25/mo |
| **Kimi 2.6** Moonshot | ~$25–35/mo | ~$50–80/mo |
| **Opus** Claude 4.7 | ~$200–400/mo (no caching) | ~$50–150/mo with aggressive prompt caching |

Tools layered on top (free):

| Service | Pricing |
|---|---|
| Groq Whisper (voice) | Free (8h/day) |
| Gemini Vision (photos) | Free tier |
| Tavily Search | Free tier (1000/mo) |

**Why DeepSeek is the only honest answer:** at $0.14/M input + $0.28/M output, an active daily user pays about **$2 a month**. Not $0.05. Not "$2 lasts a year." About **$2 a month** — and that's still cheaper than every alternative on this list by 2× to 200×. The $2 starter credit DeepSeek requires you to top up will last roughly **one month** of active use. When it runs out, top up another $2 and keep going.

*Prices as of May 2026. AI providers change pricing frequently — verify on the official pricing page before committing. Numbers above are realistic estimates for an active chat-bot user, not lab benchmarks.*

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
- **Windows** — Windows 10 (1809+) and Windows 11, native PowerShell, no WSL needed (uses Git Bash). *Beta — please report bugs.*
- **No computer at all? → [Mavka Light](mavka-light/)** — runs on Fly.io free cloud, $0/month. For people who want a Telegram AI bot without owning a Mac/Linux/Windows machine.

## Daily Commands

**macOS / Linux:**
```bash
tail -f ~/mavka-bot/mavka.log      # logs
tmux attach -t mavka               # attach to console (Ctrl+b d to detach)
bash ~/mavka-bot/launch.sh         # restart
```

**Windows:**
```powershell
mavka logs        # tail logs
mavka stop        # stop
mavka start       # start
mavka restart     # restart
mavka status      # scheduled task status
mavka uninstall   # remove autostart
```

## Why I Built This

I spent **half a day** manually setting up this same agent for my brother. SSH, configs, dependencies, Pi Agent patches, launchd plist. Hours.

Then it hit me: if a developer needs half a day, a normal person has zero chance.

MavKa is the fix. **One command. Five minutes. Done.** And while I was at it, I made sure no provider can ever lock you in.

## Status

Early days. Tested on macOS (Apple Silicon) and Arch Linux. Windows is in beta.

If something breaks — [open an issue on GitHub](https://github.com/MozgAI/MavKa/issues). If you can fix it — send a Pull Request. Everyone welcome.

## License

[MIT](LICENSE) — do whatever you want with it.

---

<p align="center"><b>Stop paying $20/month for AI you don't own.<br>Stop fighting CLIs to ship code with AI.<br>One install. ~$2 a month. Forever yours.</b></p>
<p align="center"><sub>Made with 🍃 — open source forever.</sub></p>
