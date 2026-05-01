# Mavka Light 🍃

> The free tier version of [MavKa](https://github.com/MozgAI/MavKa) — runs on Fly.io's free cloud, no laptop required.

For people who want their own AI bot in Telegram but don't have (or don't want) a Mac/Linux/Windows machine running 24/7.

## What's different from full MavKa?

| | MavKa (self-hosted) | **Mavka Light** (cloud) |
|---|---|---|
| **Where it runs** | Your laptop / desktop | Fly.io free VM |
| **You need** | Mac/Linux/Windows | Just a phone & a browser |
| **Cost** | $2 starter, ~$0.05/mo for casual chat | **Genuinely $0** if you stay in free tiers |
| **LLM brain** | DeepSeek/OpenAI/Claude/Kimi/Groq | **Groq Llama 3.3 70B (free)** |
| **Memory** | Full LLM Wiki Protocol | Same — full Wiki Protocol on a Fly.io volume |
| **Voice / Vision** | Yes | Yes if you add Gemini key (free tier) |
| **Computer use (file edit, shell)** | Yes — your machine | Limited to the VM filesystem |

## Free-tier math

- **Fly.io:** 3 shared VMs, 1 GB volume — free, no credit card required at signup
- **Groq Llama 3.3 70B:** 100K tokens / day free, 1000 requests / day — covers casual daily use
- **Gemini Vision:** free tier covers ~50 photos/day
- **Telegram:** free
- **Total: $0/month** for a real personal AI bot.

If you blow through Groq's free tier (heavy users), upgrade to a paid Groq plan or switch to DeepSeek (~$0.05/mo casual). The same `flyctl secrets set` command works for any provider.

## Deploy in 5 minutes

### 1. Create your Telegram bot

- Open Telegram, search [@BotFather](https://t.me/BotFather), send `/newbot`
- Pick a name and a `_bot` username — copy the **token** (looks like `1234567890:AAH...`)
- Search [@userinfobot](https://t.me/userinfobot), send `/start` — copy your numeric **user ID**

### 2. Get a free Groq API key

- Go to [console.groq.com](https://console.groq.com), sign up (free, no card)
- Create an API key — copy it (starts with `gsk_`)

### 3. Deploy to Fly.io

```bash
# Install flyctl once
curl -L https://fly.io/install.sh | sh
flyctl auth signup    # or `flyctl auth login` if you already have an account

# Get this repo
git clone https://github.com/MozgAI/MavKa.git
cd MavKa/mavka-light

# Provision app (creates fly.toml-bound app + persistent volume)
flyctl launch --copy-config --no-deploy --name <your-mavka-name> --region ord

# Configure secrets (these never appear in your fly.toml or git)
flyctl secrets set \
  TELEGRAM_BOT_TOKEN="1234567890:AAH..." \
  TELEGRAM_USER_ID="123456789" \
  GROQ_API_KEY="gsk_..." \
  BOT_NAME="MavKa" \
  BOT_LANG="ru"

# Optional: vision and search
# flyctl secrets set GEMINI_API_KEY="AIza..." TAVILY_API_KEY="tvly-..."

# Deploy
flyctl deploy

# Watch logs to confirm it started
flyctl logs
```

### 4. Say hi

Open Telegram, message your bot. It should answer.

## Optional configuration

| Secret | Purpose | Default |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | required |
| `TELEGRAM_USER_ID` | Your Telegram numeric ID (only this user can talk to the bot) | required |
| `GROQ_API_KEY` | Groq for the LLM brain (and Whisper) | required |
| `GEMINI_API_KEY` | Google AI Studio for photo analysis | optional |
| `TAVILY_API_KEY` | Tavily for web search | optional |
| `BOT_NAME` | What the bot calls itself | `MavKa` |
| `PERSONA` | One-paragraph personality description | "smart, friendly assistant" |
| `BOT_LANG` | Default language code | `en` |
| `PROVIDER` | LLM provider name | `groq` |
| `MODEL` | LLM model id | `llama-3.3-70b-versatile` |

To switch providers (e.g. to DeepSeek):
```bash
flyctl secrets set PROVIDER="deepseek" MODEL="deepseek-v4-flash:off" DEEPSEEK_API_KEY="sk-..."
flyctl deploy
```

## Memory and persistence

Mavka Light uses the same **LLM Wiki Protocol** as full MavKa. All memory pages live on a Fly.io volume mounted at `/home/mavka/mavka-bot`. They survive deploys, restarts, and `flyctl scale count 0` → `flyctl scale count 1`.

Backup recommendation (manual for now):
```bash
flyctl ssh sftp shell -a <your-mavka-name>
get -r /home/mavka/mavka-bot ./mavka-backup
```

Auto-backup to Cloudflare R2 / Backblaze B2 is on the v2 roadmap.

## Limits and caveats

- **Fly.io 256 MB RAM** is enough for one Pi Agent + Telegram extension. If you hit OOM, bump `[[vm]] memory` to `512mb` (~$2/mo).
- **Free tier requires periodic activity** — Fly suspends an idle app after some hours. Pi Agent polls Telegram constantly, so it stays warm.
- **No incoming HTTP** — Mavka Light only makes outbound calls (Telegram, LLM APIs). No webhooks, no exposed ports.
- **Privacy** — your data is on YOUR Fly.io account, not ours. Mavka the project never sees your messages.

## Alternatives

If Fly.io doesn't work for you:

- **Oracle Cloud Free Tier** — 4 vCPU + 24 GB RAM ARM, way more headroom. Requires credit card for verification (no charges).
- **Google Cloud e2-micro** — 1 GB RAM, free forever. Card on file.
- **Self-host on your laptop** — full [MavKa](https://github.com/MozgAI/MavKa) installer.

## License

[MIT](../LICENSE) — same as MavKa.
