#!/bin/sh
# Mavka Light — Fly.io entrypoint
# Reads config from env, seeds memory on first run, starts pi.

set -e

MAVKA_HOME="$HOME/mavka-bot"
PI_HOME="$HOME/.pi/agent"

# Required secrets (fail fast with a clear error)
: "${TELEGRAM_BOT_TOKEN:?Set TELEGRAM_BOT_TOKEN via flyctl secrets set}"
: "${TELEGRAM_USER_ID:?Set TELEGRAM_USER_ID via flyctl secrets set}"
: "${GROQ_API_KEY:?Set GROQ_API_KEY via flyctl secrets set}"

# Defaults if not provided
PROVIDER="${PROVIDER:-groq}"
MODEL="${MODEL:-llama-3.3-70b-versatile}"
BOT_NAME="${BOT_NAME:-MavKa}"
PERSONA="${PERSONA:-a smart, friendly AI assistant.}"
BOT_LANG="${BOT_LANG:-en}"

# Pi Agent provider name mapping
case "$PROVIDER" in
  groq)        PI_PROV="groq" ;;
  deepseek)    PI_PROV="deepseek" ;;
  openai)      PI_PROV="openai" ;;
  anthropic)   PI_PROV="anthropic" ;;
  moonshotai)  PI_PROV="moonshotai" ;;
  *)           PI_PROV="groq" ;;
esac

# Optional tool keys (whisper voice, gemini vision, tavily search)
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
TAVILY_API_KEY="${TAVILY_API_KEY:-}"
LLM_KEY=""
case "$PROVIDER" in
  groq)        LLM_KEY="$GROQ_API_KEY" ;;
  deepseek)    LLM_KEY="${DEEPSEEK_API_KEY:-}" ;;
  openai)      LLM_KEY="${OPENAI_API_KEY:-}" ;;
  anthropic)   LLM_KEY="${ANTHROPIC_API_KEY:-}" ;;
  moonshotai)  LLM_KEY="${MOONSHOT_API_KEY:-}" ;;
esac

# ─── First-run setup (volume is empty) ────────────────────────────
mkdir -p "$MAVKA_HOME/memory" "$MAVKA_HOME/memory/raw" "$MAVKA_HOME/memory/summaries" "$MAVKA_HOME/history" "$MAVKA_HOME/logs"
mkdir -p "$PI_HOME"

if [ ! -f "$MAVKA_HOME/memory/MEMORY.md" ]; then
  echo "[mavka-light] First run — seeding memory wiki..."
  cp -n /home/mavka/seed-memory/* "$MAVKA_HOME/memory/" 2>/dev/null || true
fi

# Render IDENTITY.md from template (env-vars expanded)
sed \
  -e "s|{{BOT_NAME}}|$BOT_NAME|g" \
  -e "s|{{PERSONA}}|$PERSONA|g" \
  -e "s|{{PROVIDER}}|$PROVIDER|g" \
  -e "s|{{BOT_LANG}}|$BOT_LANG|g" \
  /home/mavka/identity-template.md > "$MAVKA_HOME/IDENTITY.md"

# auth.json (Pi Agent format)
python3 - <<PYEOF
import json, os
auth = {}
prov = os.environ.get('PI_PROV', 'groq') if False else "$PI_PROV"
key  = "$LLM_KEY"
if key:
    auth[prov] = {"type": "api_key", "key": key}
groq_voice = "$GROQ_API_KEY"
if groq_voice and prov != "groq":
    auth["groq"] = {"type": "api_key", "key": groq_voice}
gem = "$GEMINI_API_KEY"
if gem:
    auth["google"] = {"type": "api_key", "key": gem}
with open("$PI_HOME/auth.json", "w") as f:
    json.dump(auth, f, indent=2)
os.chmod("$PI_HOME/auth.json", 0o600)
PYEOF

# telegram.json
cat > "$PI_HOME/telegram.json" <<TGJSON
{
  "botToken": "$TELEGRAM_BOT_TOKEN",
  "allowedUserId": $TELEGRAM_USER_ID,
  "lastUpdateId": 0
}
TGJSON
chmod 600 "$PI_HOME/telegram.json"

# settings.json — Pi extensions
cat > "$PI_HOME/settings.json" <<PIJSON
{
  "packages": [
    "git:github.com/badlogic/pi-telegram",
    "git:github.com/badlogic/pi-skills"
  ]
}
PIJSON

# Build the system prompt: IDENTITY + MEMORY index + frozen core
PROMPT_FILE="/tmp/mavka-prompt.md"
cat "$MAVKA_HOME/IDENTITY.md" > "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
echo "## MEMORY INDEX (as of $(date -u +%Y-%m-%d))" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
[ -f "$MAVKA_HOME/memory/MEMORY.md" ] && cat "$MAVKA_HOME/memory/MEMORY.md" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
echo "## FROZEN CORE" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
for f in "$MAVKA_HOME/memory/user_profile.md" "$MAVKA_HOME/memory/feedback_"*.md; do
  [ -f "$f" ] || continue
  case "$(basename $f)" in
    feedback_template.md) continue ;;
  esac
  echo "### $(basename $f)" >> "$PROMPT_FILE"
  cat "$f" >> "$PROMPT_FILE"
  echo "" >> "$PROMPT_FILE"
done

# ─── TCP keepalive socket on :9999 for Fly.io health check ────────
# socat works identically across alpine / debian (busybox nc flags differ).
socat -d TCP-LISTEN:9999,reuseaddr,fork SYSTEM:'echo ok' >/dev/null 2>&1 &

# Export tool keys (search.sh / tts.sh / etc would read these if installed)
export GROQ_API_KEY="$GROQ_API_KEY"
[ -n "$GEMINI_API_KEY" ] && export GEMINI_API_KEY
[ -n "$TAVILY_API_KEY" ] && export TAVILY_API_KEY

cd "$MAVKA_HOME"
echo "[mavka-light] starting pi --provider $PI_PROV --model $MODEL"
exec pi --provider "$PI_PROV" --model "$MODEL" --append-system-prompt "$PROMPT_FILE"
