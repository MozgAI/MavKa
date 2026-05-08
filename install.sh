#!/bin/bash
# MavKa 🍃 — Your personal AI assistant in Telegram
# One script. 5 minutes. Pennies a month.
#
# Recommended:  bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)
# Or local:     bash install.sh
#
# DO NOT pipe via `curl ... | bash` — this script is interactive (read prompts) and stdin
# piping breaks the prompts. Use process substitution `bash <(curl ...)` instead.
#
# Supports: macOS (Apple Silicon & Intel), Linux (x86_64, ARM)
# Requires: internet connection
set -e

# Helpful Ctrl+C / unexpected-exit message: tell the user the install is partial
# and re-running converges to a good state.
on_interrupt() {
  echo ""
  echo ""
  echo "  ⚠  Установка прервана / Installation interrupted."
  echo "     Просто запусти ту же команду заново — установщик идемпотентен:"
  echo "     Just run the same command again — the installer is idempotent:"
  echo ""
  echo "       bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/install.sh)"
  echo ""
  exit 130
}
trap on_interrupt INT TERM

# ─── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
GREY='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────
step() { echo -e "\n${GREEN}▸${NC} ${WHITE}$1${NC}"; }
info() { echo -e "  ${DIM}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} ${GREY}$1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "\n${RED}✗ $1${NC}"; exit 1; }

# Show an external sign-up / registration URL on its own line, in a
# distinct color so the user can see EXACTLY what to copy/scan. Pure
# text fallback if `qrencode` is missing — most users won't have it,
# but those who do get a free QR for mobile scan.
show_url() {
    local label="$1"
    local url="$2"
    # normalise to a full https://... URL for the QR (label keeps the short form)
    local full="$url"
    case "$full" in
        http://*|https://*) ;;
        *) full="https://$full" ;;
    esac
    echo ""
    echo -e "    ${WHITE}${BOLD}${label}${NC}"
    echo -e "      ${CYAN}${BOLD}${full}${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t ANSI -m 1 "$full" 2>/dev/null | sed 's/^/      /' || true
    fi
    echo ""
}

# Unified step header (matches the Python AI-setup style)
TOTAL_STEPS=10

# ─── AI Providers Catalog ──────────────────────────────────────
# Set by select_provider(): PROVIDER_NAME, PROVIDER_LABEL, PROVIDER_URL,
# PROVIDER_VERIFY_URL, PROVIDER_VERIFY_MODEL, PROVIDER_RUN_MODEL,
# PROVIDER_KEY_PREFIX, PROVIDER_PI_NAME, PROVIDER_NOTE.
load_provider() {
  case "$1" in
    deepseek)
      PROVIDER_NAME="deepseek"
      PROVIDER_LABEL="DeepSeek"
      PROVIDER_URL="platform.deepseek.com"
      PROVIDER_VERIFY_URL="https://api.deepseek.com/chat/completions"
      PROVIDER_VERIFY_MODEL="deepseek-chat"
      PROVIDER_RUN_MODEL="deepseek-v4-flash:off"
      PROVIDER_KEY_PREFIX="sk-"
      PROVIDER_PI_NAME="deepseek"
      PROVIDER_NOTE="Cheapest by far. ~\$2/month for active chat-bot use. \$2 starter credit ≈ 1 month."
      ;;
    openai)
      PROVIDER_NAME="openai"
      PROVIDER_LABEL="ChatGPT"
      PROVIDER_URL="platform.openai.com"
      PROVIDER_VERIFY_URL="https://api.openai.com/v1/chat/completions"
      PROVIDER_VERIFY_MODEL="gpt-4o-mini"
      PROVIDER_RUN_MODEL="gpt-4o-mini"
      PROVIDER_KEY_PREFIX="sk-"
      PROVIDER_PI_NAME="openai"
      PROVIDER_NOTE="GPT-4o-mini. ~\$5/month for active chat-bot use."
      ;;
    anthropic)
      PROVIDER_NAME="anthropic"
      PROVIDER_LABEL="Opus"
      PROVIDER_URL="console.anthropic.com"
      PROVIDER_VERIFY_URL="https://api.anthropic.com/v1/messages"
      # Verify with Haiku (cheap "hi" probe) but RUN with Opus (flagship)
      PROVIDER_VERIFY_MODEL="claude-haiku-4-5"
      PROVIDER_RUN_MODEL="claude-opus-4-7"
      PROVIDER_KEY_PREFIX="sk-ant-"
      PROVIDER_PI_NAME="anthropic"
      PROVIDER_NOTE="Claude Opus 4.7 — smartest model on the market. ~\$200–400/month for active use without prompt caching."
      ;;
    kimi)
      PROVIDER_NAME="kimi"
      PROVIDER_LABEL="Kimi 2.6"
      PROVIDER_URL="platform.moonshot.ai"
      PROVIDER_VERIFY_URL="https://api.moonshot.ai/v1/chat/completions"
      PROVIDER_VERIFY_MODEL="kimi-k2.6"
      PROVIDER_RUN_MODEL="kimi-k2.6"
      PROVIDER_KEY_PREFIX="sk-"
      PROVIDER_PI_NAME="moonshotai"
      PROVIDER_NOTE="Moonshot Kimi-K2.6. 262K context, strong on coding. ~\$25–35/month for active chat-bot use."
      ;;
    groq)
      PROVIDER_NAME="groq"
      PROVIDER_LABEL="Groq"
      PROVIDER_URL="console.groq.com"
      PROVIDER_VERIFY_URL="https://api.groq.com/openai/v1/chat/completions"
      PROVIDER_VERIFY_MODEL="llama-3.3-70b-versatile"
      PROVIDER_RUN_MODEL="llama-3.3-70b-versatile"
      PROVIDER_KEY_PREFIX="gsk_"
      PROVIDER_PI_NAME="groq"
      PROVIDER_NOTE="Free tier with daily limits. Fastest inference. \$0/month if you stay within free quota."
      ;;
  esac
}
step_header() {
  local idx="$1"        # 1-based
  local label="$2"
  local tag="$3"        # required / optional
  local filled=$((idx - 1))
  local empty=$((TOTAL_STEPS - filled))
  local bar=""
  local i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  local dots=""
  for ((i=0; i<empty; i++)); do dots="${dots}·"; done
  echo ""
  echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
  echo -e "  ${GREEN}${bar}${NC}${DIM}${dots}${NC}  ${DIM}step ${idx}/${TOTAL_STEPS}${NC}  ·  ${BOLD}${WHITE}${label}${NC}  ${DIM}${tag}${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
  echo ""
}

# ─── Detect OS ────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)  OS="linux" ;;
    *)      fail "Unsupported OS: $(uname -s). MavKa supports macOS and Linux." ;;
  esac
  ARCH="$(uname -m)"
}

# ─── Header ──────────────────────────────────────────────────
show_header() {
  clear
  echo ""
  echo -e "${GREEN}"
  echo '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗ '
  echo '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
  echo '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
  echo '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
  echo '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
  echo '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝'
  echo -e "${NC}"
  echo -e "          ${PURPLE}forest ai 🍃 alive 🍃 listening${NC}"
  echo ""
  echo -e "   ${DIM}───────────────────────────────────────────────${NC}"
  echo ""
  echo -e "   ${DIM}Platform: ${OS} (${ARCH})       Home: ~/mavka-bot${NC}"
  echo ""
}

# ─── i18n ─────────────────────────────────────────────────────
set_lang() {
  case "$1" in
    uk)
      L_step1="Крок 1: Мова";         L_step2="Крок 2: API ключі"
      L_step3="Крок 3: Telegram бот";  L_step4="Крок 4: Особистість"
      L_pick_lang="Оберіть мову бота:"
      L_get_keys="Отримайте ключі (всі безкоштовні або майже):"
      L_deepseek_key="DeepSeek API Key: "; L_groq_key="Groq API Key (голос): "
      L_gemini_key="Gemini API Key (фото): "; L_tavily_key="Tavily API Key (пошук): "
      L_ds_brain="DeepSeek — мозок MavKa"
      L_ds_url="platform.deepseek.com"
      L_ds_credit="\$2 стартового кредиту вистачає приблизно на місяць активного використання"
      L_ds_signup="Зареєструйся, поповни рахунок на \$2, створи API Key і встав сюди."
      L_verifying="Перевіряємо ключ..."
      L_ds_works="DeepSeek API ключ працює!"
      L_ai_activated="Помічник активовано!"
      L_ai_guide="MavKa проведе тебе через решту налаштування."
      L_ai_natural="Пиши природно — задавай питання, якщо щось незрозуміло."
      L_ai_skip="Пиши 'пропустити' для необов'язкових кроків."
      L_optional="(необов'язково — пропустіть для відключення)"; L_required="обов'язкове поле"
      L_lbl_lang="Мова"; L_lbl_provider="AI-провайдер"; L_lbl_api_key="API ключ"
      L_tag_required="обов'язково"; L_tag_optional="необов'язково"
      L_provider_intro="Обери мозок для бота. Можна змінити пізніше."
      L_recommended="(рекомендується)"
      L_p_deepseek_desc="~\$2/місяць, найдешевший"
      L_p_chatgpt_desc="OpenAI, API ключ"
      L_p_opus_desc="Anthropic, API ключ"
      L_p_kimi_desc="Moonshot, API ключ. Довгий контекст"
      L_p_groq_desc="Llama 3.3 70B, безкоштовний тариф з лімітами"
      L_brain_of="мозок MavKa"
      L_signup_at="Зареєструйся на"; L_create_paste="створи API ключ і встав сюди"
      L_key_works="API ключ працює!"
      L_create_bot="Створіть бота:"
      L_botfather_url="t.me/BotFather"
      L_botfather_cmd="/newbot"
      L_userid_get="Отримай свій ID:"
      L_userid_url="t.me/userinfobot"
      L_tg_token="Telegram Bot Token: "; L_tg_id="Ваш Telegram User ID: "
      L_bot_name="Ім'я бота [MavKa]: "
      L_choose_persona="Оберіть особистість або опишіть свою:"
      L_p1="Розумний асистент (за замовчуванням)"; L_p2="Дієтолог та фітнес-тренер"
      L_p3="Кухар та підбір рецептів"; L_p4="Мовний репетитор"
      L_p5="Свій варіант (опишіть)"; L_describe="Опишіть особистість бота: "
      L_ready="Готово до встановлення!"
      L_press_enter="Натисніть Enter для продовження (або Ctrl+C для скасування)..."
      L_is_ready="MavKa готова!"; L_say_hi="Відкрийте Telegram і напишіть привіт!"
      ;;
    ru)
      L_step1="Шаг 1: Язык";          L_step2="Шаг 2: API ключи"
      L_step3="Шаг 3: Telegram бот";   L_step4="Шаг 4: Личность"
      L_pick_lang="Выберите язык бота:"
      L_get_keys="Получите ключи (все бесплатные или почти):"
      L_deepseek_key="DeepSeek API Key: "; L_groq_key="Groq API Key (голос): "
      L_gemini_key="Gemini API Key (фото): "; L_tavily_key="Tavily API Key (поиск): "
      L_ds_brain="DeepSeek — мозг MavKa"
      L_ds_url="platform.deepseek.com"
      L_ds_credit="\$2 стартового кредита хватает примерно на месяц активного использования"
      L_ds_signup="Зарегистрируйся, пополни счёт на \$2, создай API Key и вставь сюда."
      L_verifying="Проверяем ключ..."
      L_ds_works="DeepSeek API ключ работает!"
      L_ai_activated="Помощник активирован!"
      L_ai_guide="MavKa проведёт тебя через остальные шаги."
      L_ai_natural="Пиши естественно — задавай вопросы, если что-то неясно."
      L_ai_skip="Пиши 'пропустить' для необязательных шагов."
      L_optional="(необязательно — пропустите для отключения)"; L_required="обязательное поле"
      L_lbl_lang="Язык"; L_lbl_provider="AI-провайдер"; L_lbl_api_key="API ключ"
      L_tag_required="обязательно"; L_tag_optional="необязательно"
      L_provider_intro="Выбери мозг для бота. Можно сменить позже."
      L_recommended="(рекомендуется)"
      L_p_deepseek_desc="~\$2/месяц, самый дешёвый"
      L_p_chatgpt_desc="OpenAI, API ключ"
      L_p_opus_desc="Anthropic, API ключ"
      L_p_kimi_desc="Moonshot, API ключ. Длинный контекст"
      L_p_groq_desc="Llama 3.3 70B, бесплатный тариф с лимитами"
      L_brain_of="мозг MavKa"
      L_signup_at="Зарегистрируйся на"; L_create_paste="создай API ключ и вставь сюда"
      L_key_works="API ключ работает!"
      L_create_bot="Создайте бота:"
      L_botfather_url="t.me/BotFather"
      L_botfather_cmd="/newbot"
      L_userid_get="Получи свой ID:"
      L_userid_url="t.me/userinfobot"
      L_tg_token="Telegram Bot Token: "; L_tg_id="Ваш Telegram User ID: "
      L_bot_name="Имя бота [MavKa]: "
      L_choose_persona="Выберите личность или опишите свою:"
      L_p1="Умный ассистент (по умолчанию)"; L_p2="Диетолог и фитнес-тренер"
      L_p3="Повар и подбор рецептов"; L_p4="Языковой репетитор"
      L_p5="Свой вариант (опишите)"; L_describe="Опишите личность бота: "
      L_ready="Готово к установке!"
      L_press_enter="Нажмите Enter для продолжения (или Ctrl+C для отмены)..."
      L_is_ready="MavKa готова!"; L_say_hi="Откройте Telegram и напишите привет!"
      ;;
    *)
      L_step1="Step 1: Language";      L_step2="Step 2: API Keys"
      L_step3="Step 3: Telegram Bot";  L_step4="Step 4: Personality"
      L_pick_lang="Choose your bot's language:"
      L_get_keys="Get your keys (all free or nearly free):"
      L_deepseek_key="DeepSeek API Key: "; L_groq_key="Groq API Key (voice): "
      L_gemini_key="Gemini API Key (photos): "; L_tavily_key="Tavily API Key (web search): "
      L_ds_brain="DeepSeek — MavKa's brain"
      L_ds_url="platform.deepseek.com"
      L_ds_credit="\$2 starter credit ≈ 1 month of active chat-bot use"
      L_ds_signup="Sign up, top up \$2, create an API key, and paste it here."
      L_verifying="Verifying API key..."
      L_ds_works="DeepSeek API key works!"
      L_ai_activated="AI Assistant activated!"
      L_ai_guide="MavKa will now guide you through the rest of setup."
      L_ai_natural="Type naturally — ask questions if anything is unclear."
      L_ai_skip="Type 'skip' to skip optional steps."
      L_optional="(optional — skip to disable)"; L_required="required"
      L_lbl_lang="Language"; L_lbl_provider="AI Provider"; L_lbl_api_key="API Key"
      L_tag_required="required"; L_tag_optional="optional"
      L_provider_intro="Pick the brain that powers your bot. You can switch later."
      L_recommended="(recommended)"
      L_p_deepseek_desc="~\$2/month, cheapest"
      L_p_chatgpt_desc="OpenAI, API key"
      L_p_opus_desc="Anthropic, API key"
      L_p_kimi_desc="Moonshot, API key. Long-context"
      L_p_groq_desc="Llama 3.3 70B, free tier with daily limits"
      L_brain_of="MavKa's brain"
      L_signup_at="Sign up at"; L_create_paste="create an API key and paste it here"
      L_key_works="API key works!"
      L_create_bot="Create a bot:"
      L_botfather_url="t.me/BotFather"
      L_botfather_cmd="/newbot"
      L_userid_get="Get your ID:"
      L_userid_url="t.me/userinfobot"
      L_tg_token="Telegram Bot Token: "; L_tg_id="Your Telegram User ID: "
      L_bot_name="Bot name [MavKa]: "
      L_choose_persona="Choose a personality or write your own:"
      L_p1="Smart assistant (default)"; L_p2="Nutritionist & fitness coach"
      L_p3="Chef & recipe finder"; L_p4="Language tutor"
      L_p5="Custom (you describe it)"; L_describe="Describe your bot's personality: "
      L_ready="Ready to install!"
      L_press_enter="Press Enter to continue (or Ctrl+C to cancel)..."
      L_is_ready="MavKa is ready!"; L_say_hi="Open Telegram and say hi!"
      ;;
  esac
}

# ─── Collect Info ─────────────────────────────────────────────
collect_info() {
  # Step 1: Language (label is universal — "Language" before user has picked a language)
  step_header 1 "Language" "required"
  echo -e "  🇬🇧  ${WHITE}1${NC} ${DIM}English${NC}      🇺🇦  ${WHITE}2${NC} ${DIM}Українська${NC}    🇩🇪  ${WHITE}3${NC} ${DIM}Deutsch${NC}"
  echo -e "  🇫🇷  ${WHITE}4${NC} ${DIM}Français${NC}     🇪🇸  ${WHITE}5${NC} ${DIM}Español${NC}       🇷🇺  ${WHITE}6${NC} ${DIM}Русский${NC}"
  echo ""
  echo -e "  ${DIM}Pick / Оберіть / Choisissez (1–6)${NC}"

  read -p "  ▸ " LANG_CHOICE
  case "${LANG_CHOICE:-1}" in
    1) BOT_LANG="en" ;;
    2) BOT_LANG="uk" ;;
    3) BOT_LANG="de" ;;
    4) BOT_LANG="fr" ;;
    5) BOT_LANG="es" ;;
    6) BOT_LANG="ru" ;;
    *) BOT_LANG="en" ;;
  esac

  set_lang "$BOT_LANG"

  # Step 2: AI Provider
  step_header 2 "$L_lbl_provider" "$L_tag_required"
  echo -e "  ${DIM}$L_provider_intro${NC}"
  echo ""
  echo -e "  ${WHITE}1${NC} ${BOLD}DeepSeek${NC}     ${DIM}— $L_p_deepseek_desc${NC}  ${PURPLE}$L_recommended${NC}"
  echo -e "  ${WHITE}2${NC} ${BOLD}ChatGPT${NC}      ${DIM}— $L_p_chatgpt_desc${NC}"
  echo -e "  ${WHITE}3${NC} ${BOLD}Opus${NC}         ${DIM}— $L_p_opus_desc${NC}"
  echo -e "  ${WHITE}4${NC} ${BOLD}Kimi 2.6${NC}     ${DIM}— $L_p_kimi_desc${NC}"
  echo -e "  ${WHITE}5${NC} ${BOLD}Groq${NC}         ${DIM}— $L_p_groq_desc${NC}"
  echo ""

  read -p "  ▸ " PROV_CHOICE
  case "${PROV_CHOICE:-1}" in
    1) load_provider "deepseek" ;;
    2) load_provider "openai" ;;
    3) load_provider "anthropic" ;;
    4) load_provider "kimi" ;;
    5) load_provider "groq" ;;
    *) load_provider "deepseek" ;;
  esac

  # Step 3: API Key for chosen provider
  step_header 3 "${PROVIDER_LABEL} ${L_lbl_api_key}" "$L_tag_required"
  echo -e "  ${DIM}${PROVIDER_LABEL} — ${L_brain_of} ${NC}🍃${DIM}  —  ${PURPLE}${PROVIDER_URL}${NC}"
  echo -e "  ${DIM}${PROVIDER_NOTE}${NC}"
  echo ""

  while true; do
    read -p "  ${PROVIDER_LABEL} ${L_lbl_api_key}: " PROVIDER_KEY
    [ -n "$PROVIDER_KEY" ] && break
    echo -e "  ${RED}⚠ ${PROVIDER_LABEL} ${L_lbl_api_key} — $L_required${NC}"
    echo -e "  ${DIM}  ${L_signup_at} ${PROVIDER_URL}, ${L_create_paste}.${NC}"
  done

  # Verify the key against the chosen provider
  info "$L_verifying"
  if [ "$PROVIDER_NAME" = "anthropic" ]; then
    KEY_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "x-api-key: $PROVIDER_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$PROVIDER_VERIFY_MODEL\",\"max_tokens\":1,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}" \
      "$PROVIDER_VERIFY_URL" 2>/dev/null)
  else
    KEY_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $PROVIDER_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$PROVIDER_VERIFY_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":1}" \
      "$PROVIDER_VERIFY_URL" 2>/dev/null)
  fi

  if [ "$KEY_CHECK" = "200" ]; then
    ok "${PROVIDER_LABEL} ${L_key_works}"
    echo ""
    echo -e "  ${GREEN}${BOLD}  🍃 $L_ai_activated${NC}"
    echo -e "  ${DIM}  $L_ai_guide${NC}"
    echo -e "  ${DIM}  $L_ai_natural${NC}"
    echo -e "  ${DIM}  $L_ai_skip${NC}"
    echo ""

    # Launch AI-guided setup
    export MAVKA_AI_KEY="$PROVIDER_KEY"
    export MAVKA_AI_PROVIDER="$PROVIDER_NAME"
    export MAVKA_AI_VERIFY_URL="$PROVIDER_VERIFY_URL"
    export MAVKA_AI_MODEL="$PROVIDER_VERIFY_MODEL"
    export MAVKA_LANG="$BOT_LANG"
    export MAVKA_STEP_OFFSET=3  # language + provider + key
    export MAVKA_TOTAL_STEPS=$TOTAL_STEPS
    # legacy alias for compatibility within ai_guided_setup
    export MAVKA_DS_KEY="$PROVIDER_KEY"
    DEEPSEEK_KEY="$PROVIDER_KEY"
    ai_guided_setup
  else
    warn "Could not verify API key (HTTP $KEY_CHECK). Continuing with manual setup..."
    DEEPSEEK_KEY="$PROVIDER_KEY"
    manual_collect_remaining
  fi
}

# ─── AI-Guided Setup ─────────────────────────────────────────
ai_guided_setup() {
  CONFIG_FILE="/tmp/mavka-setup-config.json"
  AI_SCRIPT="/tmp/mavka-ai-setup.py"

  cat > "$AI_SCRIPT" << 'AIEOF'
import json, sys, os, re, subprocess, textwrap

AI_KEY = os.environ.get("MAVKA_AI_KEY", os.environ.get("MAVKA_DS_KEY", ""))
AI_PROVIDER = os.environ.get("MAVKA_AI_PROVIDER", "deepseek")
AI_URL = os.environ.get("MAVKA_AI_VERIFY_URL", "https://api.deepseek.com/chat/completions")
AI_MODEL = os.environ.get("MAVKA_AI_MODEL", "deepseek-chat")
BOT_LANG = os.environ.get("MAVKA_LANG", "en")
STEP_OFFSET = int(os.environ.get("MAVKA_STEP_OFFSET", "0"))
TOTAL_STEPS = int(os.environ.get("MAVKA_TOTAL_STEPS", "7"))
CONFIG_FILE = "/tmp/mavka-setup-config.json"

LANG_NAMES = {"en": "English", "uk": "Ukrainian", "ru": "Russian", "de": "German", "fr": "French", "es": "Spanish"}
lang_name = LANG_NAMES.get(BOT_LANG, "English")

GREEN = "\033[0;32m"
PURPLE = "\033[0;35m"
WHITE = "\033[1;37m"
GREY = "\033[0;37m"
DIM = "\033[2m"
RED = "\033[0;31m"
YELLOW = "\033[0;33m"
ORANGE = "\033[38;5;208m"
NC = "\033[0m"

STEPS = [
    ("groq_key",        "Groq API Key (voice)",   False),
    ("gemini_key",      "Gemini API Key (photos)", False),
    ("tavily_key",      "Tavily API Key (search)", False),
    ("telegram_token",  "Telegram Bot Token",      True),
    ("telegram_id",     "Telegram User ID",        True),
    ("bot_name",        "Bot Name",                False),
    ("persona",         "Personality",             False),
]

config = {
    "groq_key": "", "gemini_key": "", "tavily_key": "",
    "telegram_token": "", "telegram_id": "",
    "bot_name": "MavKa",
    "persona": "a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. You are knowledgeable, concise, and always honest — if you don't know something, you say so."
}

CYAN = "\033[0;36m"
BOLD = "\033[1m"

LINE_WIDTH = 72  # wrap AI messages at this width

def ai_print(text):
    # AI message — leaf on first line, indented green text on continuations.
    # Wraps long lines at LINE_WIDTH so output never reaches the screen edge.
    print()  # gap above the message
    paragraphs = [p.strip() for p in text.strip().split("\n") if p.strip()]
    first = True
    for para in paragraphs:
        wrapped = textwrap.wrap(
            para, width=LINE_WIDTH,
            break_long_words=False, break_on_hyphens=False
        ) or [""]
        for j, line in enumerate(wrapped):
            if first and j == 0:
                print(f"  🍃 {GREEN}{line}{NC}")
                first = False
            else:
                print(f"     {GREEN}{line}{NC}")

def ai_ok(text):
    print()
    print(f"  {GREEN}✓{NC} {WHITE}{text}{NC}")

def ai_skip(text):
    print()
    print(f"  {ORANGE}◌{NC} {ORANGE}{text}{NC}")

def ai_warn(text):
    print()
    print(f"  {RED}⚠{NC} {GREY}{text}{NC}")

def step_header(step_idx, label, required):
    # step_idx is 0-based local; convert to global with offset
    global_idx = step_idx + STEP_OFFSET + 1   # 1-based for display
    filled = global_idx - 1
    empty = TOTAL_STEPS - filled
    bar = f"{GREEN}{'█' * filled}{NC}{DIM}{'·' * empty}{NC}"
    tag = f"{DIM}required{NC}" if required else f"{DIM}optional{NC}"
    print()
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print(f"  {bar}  {DIM}step {global_idx}/{TOTAL_STEPS}{NC}  ·  {BOLD}{WHITE}{label}{NC}  {tag}")
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print()

def step_done():
    print(f"\n  {DIM}─────────────────────────────────────────────────{NC}")

def call_deepseek(messages, retries=3):
    """Call the chosen AI provider for the conversational setup. Name kept for compatibility."""
    if AI_PROVIDER == "anthropic":
        return _call_anthropic(messages, retries)
    return _call_openai_compatible(messages, retries)

def _call_openai_compatible(messages, retries):
    """OpenAI-compatible chat completions: works for DeepSeek, OpenAI, Groq."""
    payload = json.dumps({
        "model": AI_MODEL,
        "messages": messages,
        "max_tokens": 400,
        "temperature": 0.5
    })
    for attempt in range(retries):
        try:
            result = subprocess.run(
                ["curl", "-s", "-X", "POST", AI_URL,
                 "-H", f"Authorization: Bearer {AI_KEY}",
                 "-H", "Content-Type: application/json",
                 "-d", payload],
                capture_output=True, text=True, timeout=30
            )
            data = json.loads(result.stdout)
            return data["choices"][0]["message"]["content"]
        except Exception:
            if attempt < retries - 1:
                import time; time.sleep(2)
    return None

def _call_anthropic(messages, retries):
    """Anthropic /v1/messages format — system prompt is separate, no `developer` role."""
    sys_msg = ""
    convo = []
    for m in messages:
        if m["role"] == "system":
            sys_msg = m["content"]
        elif m["role"] in ("user", "assistant"):
            convo.append({"role": m["role"], "content": m["content"]})
    payload_obj = {
        "model": AI_MODEL,
        "max_tokens": 400,
        "messages": convo,
    }
    if sys_msg:
        payload_obj["system"] = sys_msg
    payload = json.dumps(payload_obj)
    for attempt in range(retries):
        try:
            result = subprocess.run(
                ["curl", "-s", "-X", "POST", AI_URL,
                 "-H", f"x-api-key: {AI_KEY}",
                 "-H", "anthropic-version: 2023-06-01",
                 "-H", "Content-Type: application/json",
                 "-d", payload],
                capture_output=True, text=True, timeout=30
            )
            data = json.loads(result.stdout)
            # Anthropic returns content as a list of blocks
            blocks = data.get("content", [])
            text = "".join(b.get("text", "") for b in blocks if b.get("type") == "text")
            return text or None
        except Exception:
            if attempt < retries - 1:
                import time; time.sleep(2)
    return None

def validate_input(field, value):
    """STRICT: only return value if it matches expected key format. No fallback on length."""
    v = value.strip()
    if not v:
        return None
    if field == "groq_key":
        m = re.search(r'(gsk_[A-Za-z0-9]{20,})', v)
        return m.group(1) if m else None
    elif field == "gemini_key":
        m = re.search(r'(AI[A-Za-z0-9_-]{30,})', v)
        return m.group(1) if m else None
    elif field == "tavily_key":
        # Tavily keys: tvly-XXX (legacy), tvly-dev-XXX, tvly-prod-XXX (current).
        # Payload may contain dashes/underscores, so allow them in the token.
        m = re.search(r'(tvly-[A-Za-z0-9_-]{10,})', v)
        return m.group(1) if m else None
    elif field == "telegram_token":
        m = re.search(r'(\d{8,}:[A-Za-z0-9_-]{30,})', v)
        return m.group(1) if m else None
    elif field == "telegram_id":
        # Channels and bot accounts can have 13-15 digit IDs, regular users 9-12.
        m = re.fullmatch(r'\s*(\d{5,15})\s*\.?', v)
        return m.group(1) if m else None
    elif field == "bot_name":
        # Bot name only accepted if input looks like a name (short, no punctuation marks like ?)
        if len(v) <= 30 and "?" not in v and "!" not in v:
            return v
        return None
    elif field == "persona":
        return v
    return None

SKIP_WORDS = (
    "skip", "no", "n", "no thanks", "no thank you", "later", "next", "pass", "not now",
    "нет", "не", "ні", "ні дякую", "пропусти", "пропустить", "пропустим", "пропуск", "пропустимо",
    "потом", "позже", "пізніше", "пізніш", "не сейчас", "не зараз", "поки ні", "не надо",
    "далее", "дальше", "дальній", "наступний", "следующий", "перехід", "переходим", "переходимо",
    "не хочу", "не буду", "не треба", "без этого", "обійдусь", "обойдусь",
    "-", "",
)

def is_skip(text):
    t = text.strip().lower().rstrip(".!?,;:")
    if t in SKIP_WORDS:
        return True
    # also catch phrases that contain a skip cue ("можем потом", "сделаю позже", "let's skip")
    skip_cues = ("skip", "потом", "позже", "пізніше", "пропуст", "later", "далее", "дальше", "наступн", "следующ", "не сейчас", "не зараз", "обойд", "обійд", "без этого", "не нужно", "не треба", "без него")
    return any(cue in t for cue in skip_cues)

CMD_RE = re.compile(r'\[CMD:(skip|stay|none)\]', re.IGNORECASE)

def split_cmd(reply_text):
    """Extract the [CMD:...] tag from AI reply. Returns (visible_text, cmd) where cmd in {skip, stay, none, ''}"""
    if not reply_text:
        return "", ""
    matches = CMD_RE.findall(reply_text)
    cmd = matches[-1].lower() if matches else ""
    visible = CMD_RE.sub("", reply_text).strip()
    return visible, cmd

SYSTEM_PROMPT = f"""You are MavKa — a setup assistant inside a terminal installer.
You help users set up their personal AI Telegram bot.

LANGUAGE — CRITICAL:
- Detect the language of the user's LATEST message and ALWAYS reply in that exact language.
- Only when there is no user message yet (the very first greeting), use {lang_name}.
- If the user switches language mid-conversation, switch with them on the next reply.
- Never mix languages in one response.

STYLE:
- Concise (1-2 sentences usually).
- NO emojis.
- Professional but warm. Treat the user like a friend who's slightly intimidated by the terminal.

YOUR JOB:
Guide the user through ONE setup step at a time. The installer prepends each turn with a [STEP X] hint telling you what to ask for. You handle the conversation; the installer extracts the actual values from user input.

STEPS:
1. groq_key — Groq API key for voice transcription. OPTIONAL. Free at console.groq.com/keys — sign up, go to API Keys, create one.
2. gemini_key — Google Gemini API key for photo analysis. OPTIONAL. Free at aistudio.google.com/apikey — click "Create API key".
3. tavily_key — Tavily API key for web search. OPTIONAL. Free at app.tavily.com/home — sign up, copy key from dashboard.
4. telegram_token — Telegram Bot Token. REQUIRED. How to get it: open Telegram, search for @BotFather, send /newbot, choose a name and username, copy the token (format: 1234567890:AAH...).
5. telegram_id — Telegram numeric user ID. REQUIRED. How to get it: open Telegram, search for @userinfobot, send /start, copy the number.
6. bot_name — Name for the bot. Default: MavKa.
7. persona — Bot personality. ASK FREEFORM, not a numbered menu. Phrase it like: "What role do you want me to play? Describe me — your assistant for what? E.g. 'Be my personal coach', 'Help me with English and recipes', 'Be a study buddy for my kid'. Whatever you write becomes my personality." Accept ANY description ≥ 10 chars as the answer. The bot will save the user's reply directly as its persona. If the user writes something very short (≤9 chars) or asks a question, ask them to elaborate.

CONVERSATION RULES — VERY IMPORTANT:
- The installer (not you) decides when to advance. You signal intent via a control tag at the end of every reply.
- ALWAYS finish every reply with a single control tag on its own line — the installer hides it from the user. Choose ONE:
    [CMD:skip]   — the user wants to skip this step (clearly: "пропусти", "later", "next", "ну", "давай", "пошли дальше", typos in any layout, gibberish like "lfdfq ghjgrecnbv" if it semantically means "go ahead").
                   For REQUIRED steps, ONLY emit [CMD:skip] for telegram_token / telegram_id if the user explicitly insists they don't want to set it up at all (rare). Normally for required steps emit [CMD:stay].
    [CMD:stay]   — the user is asking a question, chatting, confused, or hasn't given a clear answer yet. Stay on this step, no skip.
    [CMD:none]   — the user pasted what looks like the actual value (key/token/ID/name/persona). The installer will validate the format itself.
- Read the user's intent carefully. If they say anything that means "yes go on / let's skip / move on / next / not now / I don't have it / fine without it / lfdfq" → emit [CMD:skip].
- If they say something like "wait / I have a question / how do I get this / what does it do" → emit [CMD:stay].
- DO NOT narrate "переходим к следующему шагу" in your visible reply — just acknowledge briefly ("Окей, пропускаем" or "Хорошо") and let the installer show the next header.
- For REQUIRED steps (telegram_token, telegram_id), even if the user says skip, emit [CMD:stay] and gently walk them through getting the value, unless they REPEATEDLY refuse — only then [CMD:skip].
- If user pastes a long string that may be the actual value, emit [CMD:none] — let the installer's regex decide.
- If user's reply is empty or ambiguous, emit [CMD:stay] and ask a clarifying question.
- NO emojis ever in your visible reply.
- NEVER output CONFIG lines.
"""

messages = [{"role": "system", "content": SYSTEM_PROMPT}]
step_idx = 0

while step_idx < len(STEPS):
    field, label, required = STEPS[step_idx]
    step_header(step_idx, label, required)

    step_msg = f"[STEP {step_idx+1}] Ask the user for: {label}."
    if required:
        step_msg += " This is REQUIRED — help them get it if they don't have it."
    else:
        step_msg += " This is optional — they can skip it."
    if step_idx == 0:
        step_msg = f"Greet the user warmly! Their DeepSeek key is set up. Now: {step_msg}"

    messages.append({"role": "user", "content": step_msg})

    response = call_deepseek(messages)
    if not response:
        ai_warn("Connection issue, retrying...")
        messages.pop()
        continue

    messages.append({"role": "assistant", "content": response})
    visible, _ = split_cmd(response)  # first AI greeting — no cmd expected
    ai_print(visible if visible else response)

    while True:
        print()
        print()  # extra gap between AI message and user prompt
        try:
            user_input = input(f"  🕊️  {WHITE}")
        except (EOFError, KeyboardInterrupt):
            print()
            ai_print("Setup cancelled. Run 'bash install.sh' to start again.")
            sys.exit(1)

        # 1. Try to extract a valid value via regex first — fast path, no API call
        extracted = validate_input(field, user_input) if field not in ("persona", "bot_name") else None
        if extracted:
            config[field] = extracted
            display_val = extracted[:8] + "•••" if len(extracted) > 12 else extracted
            ai_ok(f"{label}: {display_val}")
            step_idx += 1
            break

        # 2. Local skip detection (covers obvious cases without API call)
        if is_skip(user_input):
            if required:
                ai_warn(f"{label} is required and cannot be skipped.")
                messages.append({"role": "user", "content": "I want to skip this"})
                resp = call_deepseek(messages)
                if resp:
                    messages.append({"role": "assistant", "content": resp})
                    visible, _ = split_cmd(resp)
                    ai_print(visible if visible else resp)
                continue
            else:
                config[field] = ""
                ai_skip(f"{label} — skipped")
                step_idx += 1
                break

        choice = user_input.strip()

        # Persona — accept any non-trivial freeform description as the answer.
        # The user's own words become the bot's personality, no menu, no presets.
        # Short replies (≤9 chars) or questions fall through to AI for clarification.
        if field == "persona":
            is_question = "?" in choice or choice.lower().startswith((
                "how", "what", "why", "where", "can ", "could ",
                "как", "что", "почему", "где", "можешь",
                "як", "що", "чому", "де"
            ))
            if not is_question and len(choice) >= 10:
                config["persona"] = choice
                ai_ok("Personality set!")
                step_idx += 1
                break

        # Ask the AI to interpret intent for everything we couldn't classify locally
        messages.append({"role": "user", "content": user_input})
        resp = call_deepseek(messages)
        if not resp:
            ai_warn("Connection issue, retrying...")
            messages.pop()
            continue
        messages.append({"role": "assistant", "content": resp})
        visible, cmd = split_cmd(resp)
        ai_print(visible if visible else resp)

        if cmd == "skip":
            if required:
                # Required step — reinforce, but stay (don't advance)
                continue
            config[field] = ""
            ai_skip(f"{label} — skipped")
            step_idx += 1
            break

        if cmd == "none":
            # AI thinks user provided a value. Try field-specific extraction.
            if field == "bot_name" and 1 <= len(choice) <= 30:
                config["bot_name"] = choice
                ai_ok(f"Bot name: {choice}")
                step_idx += 1
                break
            if field == "persona" and len(choice) >= 15:
                config["persona"] = choice
                ai_ok("Personality set!")
                step_idx += 1
                break
            extracted = validate_input(field, user_input)
            if extracted:
                config[field] = extracted
                display_val = extracted[:8] + "•••" if len(extracted) > 12 else extracted
                ai_ok(f"{label}: {display_val}")
                step_idx += 1
                break
            # Couldn't validate — stay, AI's reply already informed the user.

print()
print(f"  {GREEN}{'█' * TOTAL_STEPS}{NC}  {DIM}{TOTAL_STEPS}/{TOTAL_STEPS}  all steps done{NC}")
print(f"  {DIM}─────────────────────────────────────────────────{NC}")

with open(CONFIG_FILE, "w") as f:
    json.dump(config, f)

print()
ai_print("Setup complete! Installing your bot now... 🍃")
print()
AIEOF

  python3 "$AI_SCRIPT"
  rm -f "$AI_SCRIPT"

  # Read config from AI session
  if [ -f "$CONFIG_FILE" ]; then
    GROQ_KEY=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('groq_key',''))" 2>/dev/null)
    GEMINI_KEY=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('gemini_key',''))" 2>/dev/null)
    TAVILY_KEY=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('tavily_key',''))" 2>/dev/null)
    TG_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('telegram_token',''))" 2>/dev/null)
    TG_USER_ID=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('telegram_id',''))" 2>/dev/null)
    BOT_NAME=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('bot_name','MavKa'))" 2>/dev/null)
    PERSONA=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('persona','a smart, proactive, and friendly AI assistant.'))" 2>/dev/null)
    rm -f "$CONFIG_FILE"
  fi

  # Validate required fields — fallback to manual if AI missed them
  if [ -z "$TG_TOKEN" ]; then
    echo -e "  ${RED}⚠ Telegram Bot Token is still needed.${NC}"
    while true; do
      read -p "  Telegram Bot Token: " TG_TOKEN
      [ -n "$TG_TOKEN" ] && break
      echo -e "  ${DIM}  $L_create_bot ${NC}${PURPLE}$L_botfather_url${NC} ${DIM}→ $L_botfather_cmd${NC}"
    done
  fi

  if [ -z "$TG_USER_ID" ]; then
    echo -e "  ${RED}⚠ Telegram User ID is still needed.${NC}"
    while true; do
      read -p "  Your Telegram User ID: " TG_USER_ID
      [ -n "$TG_USER_ID" ] && break
      echo -e "  ${DIM}  $L_userid_get ${NC}${PURPLE}$L_userid_url${NC}"
    done
  fi
}

# ─── Manual Fallback (if DeepSeek key fails) ─────────────────
manual_collect_remaining() {
  read -p "  $L_groq_key" GROQ_KEY
  echo -e "  ${DIM}$L_optional${NC}"

  read -p "  $L_gemini_key" GEMINI_KEY
  echo -e "  ${DIM}$L_optional${NC}"

  read -p "  $L_tavily_key" TAVILY_KEY
  echo -e "  ${DIM}$L_optional${NC}"

  echo ""
  echo -e "${GREEN}${BOLD}  $L_step3${NC}"
  echo -e "  ${DIM}$L_create_bot${NC}"
  show_url "$L_botfather_url" "$L_botfather_url"
  echo -e "  ${DIM}    $L_botfather_cmd${NC}"
  echo ""

  while true; do
    read -p "  $L_tg_token" TG_TOKEN
    [ -n "$TG_TOKEN" ] && break
    echo -e "  ${RED}⚠ Telegram Bot Token — $L_required${NC}"
    show_url "$L_botfather_url" "$L_botfather_url"
  done

  echo -e "  ${DIM}$L_userid_get${NC}"
  show_url "$L_userid_url" "$L_userid_url"

  while true; do
    read -p "  $L_tg_id" TG_USER_ID
    [ -n "$TG_USER_ID" ] && break
    echo -e "  ${RED}⚠ Telegram User ID — $L_required${NC}"
    show_url "$L_userid_url" "$L_userid_url"
  done

  echo ""
  echo -e "${GREEN}${BOLD}  $L_step4${NC}"
  echo ""

  read -p "  $L_bot_name" BOT_NAME
  BOT_NAME="${BOT_NAME:-MavKa}"

  echo ""
  echo -e "  ${DIM}$L_choose_persona${NC}"
  echo -e "  ${DIM}  1) $L_p1${NC}"
  echo -e "  ${DIM}  2) $L_p2${NC}"
  echo -e "  ${DIM}  3) $L_p3${NC}"
  echo -e "  ${DIM}  4) $L_p4${NC}"
  echo -e "  ${DIM}  5) $L_p5${NC}"
  echo ""

  read -p "  Choice [1]: " PERSONA_CHOICE
  PERSONA_CHOICE="${PERSONA_CHOICE:-1}"

  case "$PERSONA_CHOICE" in
    1) PERSONA="a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. You are knowledgeable, concise, and always honest — if you don't know something, you say so." ;;
    2) PERSONA="an expert nutritionist and fitness coach. You analyze meals (including from photos), count calories, create meal plans and workout routines. You are motivating, supportive, and science-based." ;;
    3) PERSONA="a professional chef and recipe expert. You suggest recipes based on available ingredients, dietary restrictions, and preferences. You explain techniques clearly and make cooking fun." ;;
    4) PERSONA="a patient and encouraging language tutor. You help learn new languages through conversation, correct mistakes gently, explain grammar, and adapt to the learner's level." ;;
    5) read -p "  $L_describe" PERSONA
       [ -z "$PERSONA" ] && PERSONA="a smart, proactive, and friendly AI assistant." ;;
    *) PERSONA="a smart, proactive, and friendly AI assistant." ;;
  esac

  echo ""
  echo -e "${GREEN}${BOLD}  $L_ready${NC}"
  echo -e "  ${DIM}Bot: ${BOT_NAME} | Lang: ${BOT_LANG} | Platform: ${OS}${NC}"
  echo ""
  read -p "  $L_press_enter"
}

# ─── Install Dependencies ────────────────────────────────────
install_deps() {
  step "Installing dependencies..."

  # Node.js via nvm
  if ! command -v node &>/dev/null; then
    info "Installing Node.js via nvm..."
    curl -so- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash 2>/dev/null
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install 22 2>/dev/null
    ok "Node.js $(node -v) installed"
  else
    ok "Node.js $(node -v) found"
  fi

  # Python3
  if ! command -v python3 &>/dev/null; then
    if [ "$OS" = "mac" ]; then
      info "Installing Python3..."
      if command -v brew &>/dev/null; then
        brew install python3 --quiet
      else
        fail "Python3 not found. Install it: https://python.org/downloads"
      fi
    else
      info "Installing Python3..."
      sudo apt-get install -y python3 python3-pip 2>/dev/null || \
      sudo yum install -y python3 python3-pip 2>/dev/null || \
      fail "Could not install Python3. Install manually."
    fi
    ok "Python3 installed"
  else
    ok "Python3 found"
  fi

  # tmux (preferred) — Pi Agent needs a real terminal multiplexer to detach,
  # and our /telegram-status verification depends on tmux capture-pane. On
  # macOS we install tmux even if screen is present, because the bundled
  # screen (4.00.03 from 2006) mangles UTF-8 and our screen -X hardcopy
  # capture is unreliable with it. screen stays as a last-resort fallback
  # only when tmux can't be installed.
  if command -v tmux &>/dev/null; then
    ok "tmux found"
  else
    if [ "$OS" = "linux" ]; then
      info "Installing tmux..."
      sudo apt-get install -y tmux 2>/dev/null || sudo yum install -y tmux 2>/dev/null || \
      sudo pacman -S --noconfirm tmux 2>/dev/null || true
    elif [ "$OS" = "mac" ]; then
      info "Installing tmux (required on macOS — bundled 'screen' is too old)..."
      # On a fresh Mac brew may not be installed yet — install it non-interactively
      if ! command -v brew &>/dev/null; then
        info "Installing Homebrew (one-time, ~1 minute)..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null 2>/dev/null || true
        # Add brew to PATH for this session
        if [ -x /opt/homebrew/bin/brew ]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      fi
      command -v brew &>/dev/null && brew install tmux --quiet 2>/dev/null || true
    fi
    if command -v tmux &>/dev/null; then
      ok "tmux installed"
    elif command -v screen &>/dev/null; then
      warn "Could not install tmux — falling back to screen (less reliable)"
    else
      warn "Neither tmux nor screen found — bot will run via nohup fallback."
    fi
  fi

  # MavKa runtime (built on the Pi coding agent — internal detail, not surfaced)
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  if command -v pi &>/dev/null; then
    ok "MavKa runtime found"
  else
    info "Installing MavKa runtime..."
    npm install -g @mariozechner/pi-coding-agent 2>/dev/null
    ok "MavKa runtime installed"
  fi

  # Python packages
  info "Installing Python packages..."
  if pip3 install --user edge-tts duckduckgo-search aiohttp --quiet 2>/dev/null || \
     pip3 install --user --break-system-packages edge-tts duckduckgo-search aiohttp --quiet 2>/dev/null || \
     python3 -m pip install --user edge-tts duckduckgo-search aiohttp --quiet 2>/dev/null || \
     python3 -m pip install --user --break-system-packages edge-tts duckduckgo-search aiohttp --quiet 2>/dev/null; then
    ok "Python packages installed"
  else
    warn "Some Python packages failed. Install manually: pip3 install --user edge-tts duckduckgo-search aiohttp"
  fi
}

# ─── Create Bot Files ─────────────────────────────────────────
create_files() {
  step "Creating bot files..."

  MAVKA_HOME="$HOME/mavka-bot"
  mkdir -p "$MAVKA_HOME/memory"
  mkdir -p "$MAVKA_HOME/memory/raw"
  mkdir -p "$MAVKA_HOME/memory/summaries"
  mkdir -p "$MAVKA_HOME/history"
  mkdir -p "$HOME/.pi/agent"

  # ── Seed memory wiki (LLM Wiki Protocol) ──
  TODAY="$(date +%Y-%m-%d)"
  TIMESTAMP="$(date +%Y-%m-%d\ %H:%M)"

  if [ ! -f "$MAVKA_HOME/memory/MEMORY.md" ]; then
    cat > "$MAVKA_HOME/memory/MEMORY.md" << MEMINDEXEOF
# Memory Index

This is the lean index of $BOT_NAME's long-term memory. Each line is one wiki page.
Keep this file under 200 lines. One line per page, ≤150 chars per line.
Format: \`- [Title](file.md) — one-line hook\`

## User
- [user_profile.md](user_profile.md) — basic user info (will fill in as we talk)

## Feedback / Rules of behavior
(none yet — when the user gives me a rule, I'll create a feedback_*.md page)

## Projects
(none yet — when the user mentions an active project, I'll create a project_*.md page)

## Concepts
(none yet — broad cross-cutting topics)

## Reference
(none yet — pointers to external systems / docs)
MEMINDEXEOF
  fi

  if [ ! -f "$MAVKA_HOME/memory/log.md" ]; then
    cat > "$MAVKA_HOME/memory/log.md" << MEMLOGEOF
# Memory Log

Append-only chronology of memory operations: INGEST (new fact stored), QUERY (notable lookup), LINT (audit).

Format: \`YYYY-MM-DD HH:MM | OP | details\`

---

$TIMESTAMP | INIT | $BOT_NAME memory wiki created (LLM Wiki Protocol).
MEMLOGEOF
  fi

  if [ ! -f "$MAVKA_HOME/memory/user_profile.md" ]; then
    cat > "$MAVKA_HOME/memory/user_profile.md" << USERPROFEOF
---
name: User profile
description: Core facts about the person I'm talking to (name, role, location, family, goals)
type: user
hall: facts
frozen: true
valid_from: $TODAY
---

# User profile

This is what I know about my user. I'll add facts here as I learn them through conversation.

## Basics
- **Name:** unknown
- **Location:** unknown
- **Role / occupation:** unknown
- **Languages spoken:** unknown

## Family
- (will add as I learn)

## Goals (long-term)
- (will add as I learn)

## Health / preferences worth remembering
- (will add as I learn)

---

**Frozen:** This page is the trusted core profile. To update an existing fact, mark the old line with \`(ended: YYYY-MM-DD)\` and add the new fact below it. Don't delete history.
USERPROFEOF
  fi

  if [ ! -f "$MAVKA_HOME/memory/feedback_template.md" ]; then
    cat > "$MAVKA_HOME/memory/feedback_template.md" << FBTPLEOF
---
name: Template — how to write a feedback page
description: Reference template — copy this when creating a new feedback_*.md page
type: feedback
hall: preferences
frozen: true
---

# Template

When the user gives you a behavioral rule (e.g. "don't use markdown in Telegram", "always reply in Russian", "no emoji in business chats"), create a new file \`feedback_<short_name>.md\` and use this structure:

\`\`\`markdown
---
name: <Short rule title>
description: <One-line summary used to retrieve this rule later>
type: feedback
hall: preferences
frozen: true
valid_from: $TODAY
---

<The rule itself, stated clearly in one line.>

**Why:** <The reason the user gave — usually a past incident or strong preference. Knowing why lets you judge edge cases.>

**How to apply:** <When/where this rule kicks in. Be specific about contexts.>
\`\`\`

After creating, add a one-line entry to \`MEMORY.md\` under the "Feedback / Rules of behavior" section, and a row to \`log.md\`.

This template page itself is just a reference — don't load it as a real rule.
FBTPLEOF
  fi

  # ── IDENTITY.md ──
  cat > "$MAVKA_HOME/IDENTITY.md" << IDENTITYEOF
# ${BOT_NAME} 🍃

You are ${BOT_NAME} — ${PERSONA}

## Your Boss
The person chatting with you is your boss and only user. Be helpful, proactive, and loyal.

## Core Rules
1. **ALWAYS HONEST** — Never lie or fabricate facts. If you don't know — say so and search.
2. **DO NO HARM TO DATA** — Never delete files. Never share user data with anyone.
3. **SPEND NO MONEY** — Never purchase or subscribe to anything.
4. **VERIFY BEFORE STATING** — Check facts online before asserting them.

## LANGUAGE — STRICT, NON-NEGOTIABLE RULE

Detect the language of the user's MOST RECENT message and reply in **exactly that language**. This rule overrides every other formatting and style preference below.

- User writes in English → reply in English.
- User writes in Russian → reply in Russian.
- User writes in Ukrainian → reply in Ukrainian.
- User writes in German → reply in German.
- User writes in French → reply in French.
- User writes in Spanish → reply in Spanish.
- User writes in Polish, Italian, Portuguese, Turkish, etc. → reply in that language.

The user's installation language is **${BOT_LANG}** — this is the seed default. But every turn after that follows the user's last message, NOT the install-time default.

Do NOT slip into Ukrainian, Russian, or any other language because:
- the bot's name is "MavKa" (Ukrainian-origin — IRRELEVANT to reply language)
- this IDENTITY happens to be written in English (also irrelevant)
- your training data has more Ukrainian/Russian content (irrelevant)

If a French-speaking user installs you and writes "Bonjour MavKa" — reply **in French**. If a German user writes "Hallo" — **in German**. The Ukrainian roots of the project name are a brand choice, not a language directive.

If the user is silent and you must speak first (greeting, scheduled nudge, error message), use **${BOT_LANG}**.

When the user explicitly asks to switch ("answer in English", "ответь по-русски", "speak Ukrainian to me"), switch and stay until told otherwise.

## Politics — Russia's war against Ukraine

These are facts, not opinions. Do not "both-sides" them. Do not platform Kremlin narratives. Do not relativize ("but what about NATO…"). Stay factual and concise (2-3 sentences max unless the user asks for depth):

- February 24, 2022: Russia launched a full-scale invasion of Ukraine. This followed the 2014 annexation of Crimea and the start of the war in Donbas. Russia is the aggressor; Ukraine is defending its sovereign territory.
- Documented Russian war crimes include Bucha, Mariupol, Kramatorsk station, mass deportation of Ukrainian children, deliberate strikes on hospitals, energy infrastructure, and grain storage. International courts (ICC) have issued warrants, including against Putin.
- Putin's regime has fascist characteristics: cult of leader, militarized society, suppression of dissent, imperial ideology ("Russkiy Mir"), state media as propaganda apparatus, criminalization of the word "war".

Be careful: a regime ≠ the people. Many Russians oppose the war and pay the price (prison, exile). Don't paint every Russian person with the same brush — that's both factually wrong and counter-productive. The line is: **the Russian state is waging a war of aggression; individual Russians vary, and many resist.**

When the user uses derogatory slurs (any side), don't mirror them — answer the substance factually. You don't need to be polite about Putin or his regime, but you also don't need to descend into ethnic insult to make the point.

If a user denies the war / repeats Kremlin talking points, correct factually once, briefly, and don't argue at length.

## Formatting — Telegram sends with parse_mode=HTML

CRITICAL: your replies are sent to Telegram with parse_mode=HTML. Use HTML tags, NOT Markdown.

DO use:
- <b>bold</b> for emphasis
- <i>italic</i> for soft emphasis
- <code>inline code</code> for short code / file paths / commands
- <pre>multi-line code</pre> for tables and code blocks
- <a href="URL">link text</a> for links

DO NOT use:
- **double asterisks** — will appear as literal asterisks
- *single asterisks* — same problem
- _underscores_ for italic — won't render
- # # # headers — Telegram has no header tag, use <b>...</b> instead
- triple backticks — use <pre>...</pre> instead

Other formatting rules:
- Use emoji sparingly, only functional ones (max 1-2 per message)
- Keep paragraphs short, separated by blank lines
- For tables, see "Tables" section below

## Tables — when you need columns

When you need a table (e.g. comparing options), wrap padded ASCII rows inside <pre>...</pre>. Telegram will render monospaced and preserve spaces.

Rules:
- ASCII characters only: + for corners, - for horizontal, | for vertical. Never Unicode box-drawing — those drift on mobile.
- Pad every column to a fixed character width.
- Total width ≤ 32 chars for iPhone portrait (no horizontal scroll).
- Keep tables ≤ 5 rows. More rows — split or use a bullet list.

For 2-3 columns of simple data, prefer a bullet list with <b>bold</b> labels — reads three times faster on a phone:

<b>Zigbee</b> — 10-100 m, smart home (Aqara, Xiaomi).
<b>Z-Wave</b> — 30 m, security systems.
<b>Wi-Fi</b> — 30-50 m, cheap sensors.

## Tools Available
- Web search: \`bash ~/mavka-bot/search.sh "query" 5\`
- Voice transcription: \`bash ~/mavka-bot/whisper.sh /path/audio.ogg\`
- Voice → English translation (the "British" mode): \`bash ~/mavka-bot/whisper.sh /path/audio.ogg --british\`
- Text-to-speech: \`bash ~/mavka-bot/tts.sh "text" /tmp/voice.ogg\`
- Photo analysis: \`bash ~/mavka-bot/vision.sh /path/image.jpg "question"\`
- Memory recall: \`bash ~/mavka-bot/recall.sh "query"\`  (search across the wiki, chat history, and distilled summaries)
- Memory lint: \`bash ~/mavka-bot/lint.sh\`  (audit pages — run when the user asks "проверь память")
- Hot-swap API key: \`bash ~/mavka-bot/setkey.sh <provider> <new_key>\`  (deepseek/openai/anthropic/moonshotai/groq/google/tavily)
- Token statusline: \`bash ~/mavka-bot/token.sh\`  (returns TWO lines of plain text — bar + counter, then a phrase; only invoke on the explicit "токен" trigger below)

## "Token" trigger — two-line context-usage indicator

When the user writes the word **"токен"** / **"token"** as a STANDALONE message (not inside a sentence like "сколько у нас токенов" — those are normal questions, answer them in prose), reply with the **verbatim output of \`bash ~/mavka-bot/token.sh\`** as plain text. The script returns TWO lines:

1. The bar plus the counter (\`<bar> <K>K/200K\`) — emoji squares carry the visual themselves
2. A one-line Gilfoyle-deadpan phrase tied to the cube count

Send both lines as printed, in order, with no extra wrappers, prefixes, greetings, commentary, asterisks, backticks, \`<code>\`, or quotes. Pure plain text. The asterisk-wrapped bold version was tried and pi-telegram leaves the asterisks visible — so we drop them.

Example:

User: токен
You:
🟧🟧🟧🟧🟧🟧🟧⬛⬛⬛ 135K/200K
RAM держится на кофеине и сексуальном напряжении

Two-tone thermometer: every filled cube is the same colour, every empty cube is ⬛. Colour is chosen by cube count — 1-2 🟩 green, 3-5 🟨 yellow, 6-8 🟧 orange, 9-10 🟥 red. The phrase comes from a fixed table inside the script, indexed by cube count (0..10) plus an overflow line at 11, in the install language. Numbers, bar, and phrase all come from the script — never paraphrase or invent.

## "British" mode — instant voice-to-English translation

When the user says "Британец", "позови Британця", "включи британца", or anything semantically equivalent — switch into British mode:
1. Create marker: \`touch ~/mavka-bot/.british_mode\`
2. Reply: "Диктуй, переведу" (or similar one-line acknowledgement)
3. From now on, when a voice message arrives, run \`whisper.sh <audio> --british\` instead of normal whisper. The output is English text (Whisper translates natively, no LLM step needed).
4. Reply with ONLY the translated text inside a triple-backtick code block. No prefixes, no flags, no commentary, no "here's the translation". Just the code block. Like this:
\\\`\\\`\\\`
Hello, today I went to the gym and met John there.
\\\`\\\`\\\`

When the user says "вимкни Британця" / "хватит" / "выключи британца" — \`rm ~/mavka-bot/.british_mode\` and confirm in one short sentence. Voice messages return to normal transcription.

Check the marker file at the start of every voice handler to know which mode is active.

## Hot-swap API key — when the user wants to change provider keys

If the user says "поменяй ключ на ...", "вот новый ключ для DeepSeek: sk-...", "хочу переподключить openai с новым ключом" or anything similar:
1. Identify the provider name from context (deepseek / openai / anthropic / moonshotai / groq / google / tavily).
2. Run \`bash ~/mavka-bot/setkey.sh <provider> <new_key>\`.
3. The script updates auth.json (or start.sh for tavily), runs chmod 0600, and restarts MavKa automatically.
4. Confirm to the user: "Ключ обновлён, бот перезапущен. Готово." (or the equivalent in their language).

This is the ONLY supported way to change keys after installation — never tell the user to re-run install.sh just to change a key.

## Memory System — LLM Wiki Protocol

You have persistent long-term memory in ~/mavka-bot/memory/. Every important fact about the user, their projects, their preferences, their decisions — lives in this wiki and survives restarts. This is your "second brain."

### Structure

- ~/mavka-bot/memory/MEMORY.md          ← INDEX, lean (≤200 lines), one line per page
- ~/mavka-bot/memory/log.md             ← append-only audit (INGEST/QUERY/LINT events)
- ~/mavka-bot/memory/user_profile.md    ← FROZEN: who the user is
- ~/mavka-bot/memory/feedback_*.md      ← FROZEN: rules of behavior the user gave you
- ~/mavka-bot/memory/project_*.md       ← active projects, goals, deadlines
- ~/mavka-bot/memory/concept_*.md       ← generalizing pages (cross-cutting topics)
- ~/mavka-bot/memory/raw/               ← raw sources (pasted articles, screenshots)

### Page format (frontmatter at top of every page)

\`\`\`
---
name: <short title>
description: <one-line hook used to decide relevance later — be specific>
type: user | feedback | project | reference | concept
hall: facts | events | discoveries | preferences | advice
frozen: true            (optional — locks the page from rewrites)
valid_from: 2026-04-30  (optional — date the fact became true)
ended: 2026-12-01       (optional — date the fact stopped being true)
---

<page body>
\`\`\`

For feedback/project/concept pages, lead with the rule, then add a **Why:** line and a **How to apply:** line.

### Halls (semantic taxonomy — answers "what kind of memory is this")

- facts — stable truths (user_profile, setup, references)
- events — time-bound (project status, deadlines, incidents)
- discoveries — generalizations / insights
- preferences — what the user wants (style, format, tone)
- advice — corrective rules ("don't do X because…")

### Operations

**ON EVERY TURN — QUERY (cheap path):**
1. The MEMORY.md index is already in your system prompt — see what pages exist.
2. Open ONLY the pages relevant to this question (use your read tool).
3. When citing a memory fact, mention which page it came from.
4. If memory disagrees with new info, trust the new info but mark for INGEST.

**WHEN YOU LEARN SOMETHING NEW — INGEST:**
1. Decide which existing page it belongs to, or create a new one with proper frontmatter.
2. NEVER overwrite a frozen page — only add cross-links to it like [[other_page.md]].
3. PREFER creating a new concept page over rewriting old ones (drift protection).
4. Update temporal fields if the fact has a lifecycle (valid_from / ended).
5. Append a one-line entry to log.md in this exact format:
   \`YYYY-MM-DD HH:MM | INGEST | <what> → <pages>\`
6. If you create a new page, add a one-line pointer to MEMORY.md (one line, ≤150 chars).

**WHEN AMBIGUOUS — DO NOT HALLUCINATE:**
- If you don't know, write "unknown" — never invent.
- Every fact needs provenance (raw/, prior conversation, URL).
- Convert relative dates to absolute when saving ("Thursday" → "2026-05-08").

### Critical rules (NEVER break)

1. NEVER delete a memory page without explicit user confirmation.
2. Frozen pages are read-only for content. You can add cross-links to them.
3. MEMORY.md is the index — keep it under 200 lines, one line per page.
4. Don't write conversation history into memory. Memory is for facts, decisions, preferences — not chat logs.
5. Don't duplicate. Before creating a new page, search MEMORY.md for an existing page that covers it.
6. raw/ is the first source of truth — wiki pages are summaries.

### Format examples (HYPOTHETICAL — these are the SHAPE of a page, not data about the user)

DO NOT treat the names, places, or projects below as real facts about your user. They are just there to show frontmatter and structure. Your user's actual data starts empty.

Example 1 — a feedback page (made-up rule for illustration):
\`\`\`
---
name: <short rule title>
description: <one-line summary used for retrieval>
type: feedback
hall: preferences
frozen: true
---
<The rule itself, one clear sentence.>

**Why:** <reason the user gave>
**How to apply:** <when/where the rule kicks in>
\`\`\`

Example 2 — a project page (made-up project for illustration):
\`\`\`
---
name: <project name>
description: <one-line description for retrieval>
type: project
hall: events
valid_from: <YYYY-MM-DD when the project started>
---
<one-paragraph description>

**Goal:** <what success looks like>

[[user_profile.md]]
\`\`\`

## Identity
- **Provider:** ${PROVIDER_LABEL}
- **You are NOT Claude, NOT GPT, NOT Gemini.** You are ${BOT_NAME}.
- The runtime under the hood is an internal detail — never mention "Pi", "pi-coding-agent", "Pi Agent" or related strings to the user. Brand is **${BOT_NAME} 🍃**.
IDENTITYEOF

  ok "Identity created"

  # ── start.sh ──
  # Resolve node and pi paths NOW so the autostart entry doesn't depend on
  # an nvm version that may change. Bake absolute paths into the script.
  NODE_BIN="$(command -v node)"
  NODE_DIR="$(dirname "$NODE_BIN")"
  # Map provider name → canonical env var name the rest of the toolchain uses
  case "${PROVIDER_NAME:-deepseek}" in
    deepseek)    PROVIDER_KEY_VAR="DEEPSEEK_API_KEY" ;;
    openai)      PROVIDER_KEY_VAR="OPENAI_API_KEY" ;;
    anthropic)   PROVIDER_KEY_VAR="ANTHROPIC_API_KEY" ;;
    moonshotai)  PROVIDER_KEY_VAR="MOONSHOT_API_KEY" ;;
    groq)        PROVIDER_KEY_VAR="GROQ_API_KEY" ;;
    *)           PROVIDER_KEY_VAR="DEEPSEEK_API_KEY" ;;
  esac
  CHOSEN_LLM_KEY="${PROVIDER_KEY:-$DEEPSEEK_KEY}"

  cat > "$MAVKA_HOME/start.sh" << STARTEOF
#!/bin/bash
export HOME="$HOME"
# Force UTF-8 locale: Pi's TUI uses box-drawing characters and emoji, and
# the user often types Cyrillic. On terminals that inherit LANG=C / no
# locale, all of this turns into mojibake (??? and âââ characters). Force
# the most widely-available UTF-8 locale before launching Pi.
export LANG="\${LANG:-en_US.UTF-8}"
case "\$LANG" in
  *.UTF-8|*.utf8|*.UTF8) ;;
  *) export LANG="en_US.UTF-8" ;;
esac
export LC_ALL="\$LANG"
export LC_CTYPE="\$LANG"

# Hardcode the resolved node bin dir so this survives nvm version bumps.
export PATH="${NODE_DIR}:\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"
# Re-source nvm if present (covers manual node updates without breaking us)
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

# Provider key under the canonical env var name (DEEPSEEK_API_KEY / OPENAI_API_KEY / etc)
export ${PROVIDER_KEY_VAR}="${CHOSEN_LLM_KEY}"
# Tool keys (independent of LLM provider)
export GROQ_API_KEY="${GROQ_KEY}"
export GEMINI_API_KEY="${GEMINI_KEY}"
export TAVILY_API_KEY="${TAVILY_KEY}"

# Suppress pi-coding-agent's "New version is available" banner (it's a noisy
# distraction for end users — MavKa updates ride alongside our installer).
export PI_SKIP_VERSION_CHECK=1

cd "\$HOME/mavka-bot"

PROMPT_FILE="/tmp/mavka-prompt.md"
cat "\$HOME/mavka-bot/IDENTITY.md" > "\$PROMPT_FILE"
echo "" >> "\$PROMPT_FILE"

# LLM Wiki: load only the lean index + frozen core (≤2K tokens total).
# Detail pages are read on-demand by the agent through its read tool.
echo "## MEMORY INDEX (as of \$(date +%Y-%m-%d))" >> "\$PROMPT_FILE"
echo "" >> "\$PROMPT_FILE"
if [ -f "\$HOME/mavka-bot/memory/MEMORY.md" ]; then
  cat "\$HOME/mavka-bot/memory/MEMORY.md" >> "\$PROMPT_FILE"
fi
echo "" >> "\$PROMPT_FILE"
echo "## FROZEN CORE" >> "\$PROMPT_FILE"
echo "" >> "\$PROMPT_FILE"
# Inline only the frozen pages (user_profile + real feedback_*.md) — they're stable
# and small. Everything else is read on demand. The template is excluded — it's a reference,
# not a rule.
for f in "\$HOME/mavka-bot/memory/user_profile.md" "\$HOME/mavka-bot/memory/feedback_"*.md; do
  [ -f "\$f" ] || continue
  case "\$(basename \$f)" in
    feedback_template.md) continue ;;
  esac
  echo "### \$(basename \$f)" >> "\$PROMPT_FILE"
  cat "\$f" >> "\$PROMPT_FILE"
  echo "" >> "\$PROMPT_FILE"
done

# Pi auto-discovers extensions in ~/.pi/agent/extensions/. The sandbox extension
# (if installed) loads automatically — no flag needed.
exec pi --provider ${PROVIDER_PI_NAME} --model ${PROVIDER_RUN_MODEL} \\
   --append-system-prompt "\$PROMPT_FILE"
STARTEOF
  chmod +x "$MAVKA_HOME/start.sh"
  ok "Start script created"

  # ── launch.sh (tmux/screen/nohup wrapper — Pi Agent needs TTY) ──
  # After spawning the session we wait for it to actually exist, then
  # explicitly type /telegram-connect into Pi so the bridge wakes up.
  # Both creation and the connect call are *verified* — failures are
  # logged as ERROR so the user can see exactly what broke instead of a
  # silent "looks fine but Telegram is dead" outcome.
  # Also uses flock around the spawn to avoid races between this manual
  # call and a parallel autostart (LaunchAgent/systemd RunAtLoad).
  cat > "$MAVKA_HOME/launch.sh" << 'LAUNCHEOF'
#!/bin/bash
LOGFILE="$HOME/mavka-bot/mavka.log"
LOCKFILE="$HOME/mavka-bot/.launch.lock"
echo "$(date): Starting MavKa..." >> "$LOGFILE"

# Serialise launches: prevent autostart + manual launch from racing each
# other and killing one another's session mid-spawn.
exec 9>"$LOCKFILE"
if command -v flock >/dev/null 2>&1; then
  flock -w 30 9 || { echo "$(date): WARN: could not acquire launch lock, proceeding" >> "$LOGFILE"; }
fi

session_alive() {
  if command -v tmux &>/dev/null && tmux has-session -t mavka 2>/dev/null; then
    return 0
  fi
  if command -v screen &>/dev/null && screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'; then
    return 0
  fi
  return 1
}

# Verify telegram bridge is actually polling — not just that we typed
# /telegram-connect into the void. Captures the pane, checks for the
# "polling" / "connected" success marker; if absent, re-fires
# /telegram-connect and retries up to 5 times with backoff.
verify_telegram_bridge() {
  local backend="$1"  # tmux | screen
  local snap=""
  for attempt in 1 2 3 4 5; do
    sleep 4
    if [ "$backend" = "tmux" ]; then
      tmux send-keys -t mavka "/telegram-status" Enter 2>/dev/null || true
      sleep 3
      snap=$(tmux capture-pane -pt mavka -S -200 2>/dev/null || echo "")
    else
      screen -S mavka -X hardcopy /tmp/mavka_pane.$$ 2>/dev/null || true
      sleep 1
      snap=$(cat /tmp/mavka_pane.$$ 2>/dev/null || echo "")
      rm -f /tmp/mavka_pane.$$
    fi
    if echo "$snap" | grep -qiE 'polling|telegram (connected|active)|listening on'; then
      echo "$(date): telegram bridge VERIFIED (attempt $attempt, $backend)" >> "$LOGFILE"
      return 0
    fi
    echo "$(date): telegram bridge not yet up (attempt $attempt, $backend) — re-firing /telegram-connect" >> "$LOGFILE"
    if [ "$backend" = "tmux" ]; then
      tmux send-keys -t mavka "/telegram-connect" Enter 2>/dev/null || true
    else
      screen -S mavka -p 0 -X stuff "/telegram-connect"$'\n' 2>/dev/null || true
    fi
  done
  echo "$(date): ERROR: telegram bridge NOT verified after 5 attempts. Last pane snapshot:" >> "$LOGFILE"
  echo "$snap" | tail -30 >> "$LOGFILE"
  return 1
}

# All output kept in $LOGFILE — nothing technical printed to user's terminal.
if command -v tmux &>/dev/null; then
  tmux kill-session -t mavka >/dev/null 2>&1 || true
  sleep 1
  # -u forces UTF-8 mode (required for Cyrillic + emoji rendering)
  # -n names the window "MavKa 🍃" so the status bar isn't "0:node*"
  tmux -u new-session -d -s mavka -n 'MavKa 🍃' "bash $HOME/mavka-bot/start.sh" 2>>"$LOGFILE" || true
  # Wait up to 8s for the session to actually exist before sending keys.
  for i in 1 2 3 4 5 6 7 8; do
    tmux has-session -t mavka 2>/dev/null && break
    sleep 1
  done
  if tmux has-session -t mavka 2>/dev/null; then
    # Branded green status bar — session-scoped (doesn't affect user's other tmux work)
    tmux set-option -t mavka status-style 'bg=colour22,fg=white' 2>/dev/null || true
    tmux set-option -t mavka window-status-current-style 'bg=colour71,fg=black,bold' 2>/dev/null || true
    tmux set-option -t mavka status-left ' 🍃 MavKa ' 2>/dev/null || true
    tmux set-option -t mavka status-right ' #(date +%H:%M) ' 2>/dev/null || true
    echo "$(date): MavKa launched in tmux session" >> "$LOGFILE"
    sleep 6  # let pi finish bootstrap and load extensions
    if tmux send-keys -t mavka "/telegram-connect" Enter 2>>"$LOGFILE"; then
      echo "$(date): /telegram-connect sent (tmux)" >> "$LOGFILE"
      verify_telegram_bridge tmux || true
    else
      echo "$(date): ERROR: /telegram-connect send failed (tmux)" >> "$LOGFILE"
    fi
  else
    echo "$(date): ERROR: tmux session did not start" >> "$LOGFILE"
  fi
elif command -v screen &>/dev/null; then
  # macOS screen prints "No screen session found" to STDOUT (not stderr) when
  # there's nothing to kill — redirect both streams.
  { screen -ls 2>/dev/null | awk '/^[[:space:]]*[0-9]+\.mavka[[:space:]]/{print $1}' | xargs -I{} screen -S {} -X quit >/dev/null 2>&1; screen -wipe >/dev/null 2>&1; } || true
  sleep 1
  # -U forces UTF-8 mode (without it, macOS screen mangles Cyrillic + emoji)
  screen -U -dmS mavka bash "$HOME/mavka-bot/start.sh" 2>>"$LOGFILE" || true
  for i in 1 2 3 4 5 6 7 8; do
    screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]' && break
    sleep 1
  done
  if screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'; then
    echo "$(date): MavKa launched in screen session" >> "$LOGFILE"
    sleep 6  # let pi finish bootstrap and load extensions
    if screen -S mavka -p 0 -X stuff "/telegram-connect"$'\n' 2>>"$LOGFILE"; then
      echo "$(date): /telegram-connect sent (screen)" >> "$LOGFILE"
      verify_telegram_bridge screen || true
    else
      echo "$(date): ERROR: /telegram-connect stuff failed (screen)" >> "$LOGFILE"
    fi
  else
    echo "$(date): ERROR: screen session did not start" >> "$LOGFILE"
  fi
else
  # Final fallback: nohup. No interactive attach available, but the bot runs.
  pkill -f "mavka-bot/start.sh" 2>/dev/null || true
  sleep 1
  nohup bash "$HOME/mavka-bot/start.sh" >>"$LOGFILE" 2>&1 &
  echo "$(date): MavKa launched via nohup (PID $!)" >> "$LOGFILE"
  echo "$(date): WARN: nohup mode, no terminal to fire /telegram-connect — bridge may not wake" >> "$LOGFILE"
fi
LAUNCHEOF
  chmod +x "$MAVKA_HOME/launch.sh"
  ok "Launcher created"

  # ── mavka cli (single-word entry point) ──
  # `mavka` (no args) — interactive chat with the bot in this terminal
  # (attaches to the running screen session if alive, falls back to fresh
  # foreground Pi). All other subcommands map to existing scripts.
  cat > "$MAVKA_HOME/mavka" << 'MAVKAEOF'
#!/bin/bash
# MavKa 🍃 — single-word CLI. Run `mavka` to talk to the bot in this
# terminal, `mavka logs` to tail logs, etc.

MAVKA_HOME="$HOME/mavka-bot"
ACTION="${1:-chat}"

# Green ASCII banner — visible the moment user attaches / starts MavKa.
# 256-color green where supported, fall back gracefully on dumb terminals.
mavka_banner() {
  if [ -t 1 ]; then
    G=$'\033[38;5;71m'      # brand green
    GD=$'\033[38;5;65m'     # darker accent
    GB=$'\033[1;38;5;77m'   # bright bold green
    NC=$'\033[0m'
  else
    G=""; GD=""; GB=""; NC=""
  fi
  echo ""
  echo "${G}   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗ ${NC}"
  echo "${G}   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗${NC}"
  echo "${G}   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║${NC}"
  echo "${G}   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║${NC}"
  echo "${GB}   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║${NC}"
  echo "${GB}   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝${NC}"
  echo "${GD}   🍃   🍃   🍃   🍃   🍃   🍃   🍃   🍃   🍃${NC}"
  echo ""
}

# Apply branded green tmux look to the mavka session (status bar, window
# name). Session-scoped — won't touch user's other tmux sessions.
tmux_brand() {
  tmux set-option -t mavka status-style 'bg=colour22,fg=white' 2>/dev/null
  tmux set-option -t mavka window-status-current-style 'bg=colour71,fg=black,bold' 2>/dev/null
  tmux set-option -t mavka status-left ' 🍃 MavKa ' 2>/dev/null
  tmux set-option -t mavka status-right ' #(date +%H:%M) ' 2>/dev/null
  tmux rename-window -t mavka:0 'MavKa 🍃' 2>/dev/null
}

case "$ACTION" in
  chat|"")
    mavka_banner
    # Attach to running session if it's there, otherwise spawn fresh in
    # foreground so the user gets an interactive MavKa prompt right here.
    # tmux -u / screen -U force UTF-8 mode so Cyrillic + emoji render
    # correctly on macOS where terminals can default to non-UTF-8.
    if command -v tmux >/dev/null 2>&1 && tmux has-session -t mavka 2>/dev/null; then
      tmux_brand
      echo "🍃 Підключаюсь до MavKa (Ctrl+b d щоб від'єднатись)…"
      tmux -u attach -t mavka
    elif command -v screen >/dev/null 2>&1 && screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'; then
      echo "🍃 Підключаюсь до MavKa (Ctrl+A → D щоб від'єднатись, НЕ Ctrl+C)…"
      # -U forces UTF-8; -x joins an already-attached session; -D -RR
      # forces a fresh re-attach if no clean -x is possible.
      screen -U -x mavka 2>/dev/null || screen -U -D -RR mavka
    elif command -v tmux >/dev/null 2>&1; then
      echo "🍃 Стартую MavKa тут. Type /exit to quit."
      tmux -u new-session -A -s mavka -n 'MavKa 🍃' "bash $MAVKA_HOME/start.sh" &
      sleep 1
      tmux_brand
      tmux -u attach -t mavka
    else
      echo "🍃 No running session — starting MavKa here. Type /exit to quit."
      bash "$MAVKA_HOME/start.sh"
    fi
    ;;
  start)
    bash "$MAVKA_HOME/launch.sh"
    echo 'MavKa started. Run: mavka logs'
    ;;
  stop)
    if [ -f "$HOME/Library/LaunchAgents/com.mavka.bot.plist" ]; then
      launchctl unload "$HOME/Library/LaunchAgents/com.mavka.bot.plist" 2>/dev/null
    fi
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user stop mavka 2>/dev/null
    fi
    tmux kill-session -t mavka 2>/dev/null
    screen -ls 2>/dev/null | awk '/^[[:space:]]*[0-9]+\.mavka[[:space:]]/{print $1}' | xargs -I{} screen -S {} -X quit >/dev/null 2>&1
    pkill -f "mavka-bot/start.sh" 2>/dev/null
    echo "MavKa stopped."
    ;;
  restart)
    "$0" stop
    sleep 2
    "$0" start
    ;;
  logs)
    tail -f "$MAVKA_HOME/mavka.log"
    ;;
  status)
    if (tmux list-sessions 2>/dev/null | grep -q mavka) || \
       (screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'); then
      echo "running"
    else
      echo "stopped"
    fi
    ;;
  doctor)
    # Health check — designed to catch every install-time root cause Codex's
    # 2026-05-08 deep audit uncovered. Each row prints OK/WARN/FAIL + reason.
    PASS=0; WARN=0; FAIL=0
    g() { printf "  \033[32m✓\033[0m %s\n" "$1"; PASS=$((PASS+1)); }
    y() { printf "  \033[33m!\033[0m %s\n" "$1"; WARN=$((WARN+1)); }
    r() { printf "  \033[31m✗\033[0m %s\n" "$1"; FAIL=$((FAIL+1)); }
    echo "🍃 MavKa doctor — full health check"
    echo ""

    # 1. pi binary
    if command -v pi >/dev/null 2>&1; then
      PI_VER=$(pi --version 2>/dev/null | head -1)
      g "pi binary present (${PI_VER:-version unknown})"
    else
      r "pi binary not in PATH — run installer again"
    fi

    # 2. settings.json — telegram extension package wired up
    SET="$HOME/.pi/agent/settings.json"
    if [ -f "$SET" ]; then
      if grep -q "pi-telegram" "$SET"; then
        g "settings.json references pi-telegram"
      else
        r "settings.json exists but pi-telegram extension not registered"
      fi
    else
      r "$SET missing — Pi never finished onboarding"
    fi

    # 3. pi-telegram source on disk + node_modules
    PI_TG_DIR="$HOME/.pi/agent/git/github.com/badlogic/pi-telegram"
    if [ -d "$PI_TG_DIR" ]; then
      g "pi-telegram cloned at $PI_TG_DIR"
      if [ -d "$PI_TG_DIR/node_modules" ]; then
        g "pi-telegram node_modules present"
      else
        r "pi-telegram node_modules missing — run: cd $PI_TG_DIR && npm install"
      fi
      # 4. session_start has the startPolling patch (Codex P0.1)
      INDEX="$PI_TG_DIR/index.ts"
      if [ -f "$INDEX" ]; then
        if grep -q "startPolling" "$INDEX"; then
          g "pi-telegram session_start has startPolling (patch applied)"
        else
          r "pi-telegram session_start NOT patched — telegram bridge will silently no-op"
        fi
      else
        r "pi-telegram index.ts missing — upstream layout changed?"
      fi
    else
      r "pi-telegram not cloned — installer's first_run did not finish"
    fi

    # 5. telegram.json (token + user id)
    TG_JSON="$HOME/.pi/agent/telegram.json"
    if [ -f "$TG_JSON" ]; then
      if grep -q "botToken" "$TG_JSON" && grep -q "allowedUserIds" "$TG_JSON"; then
        g "telegram.json has botToken + allowedUserIds"
      else
        r "telegram.json malformed — re-run installer"
      fi
    else
      r "$TG_JSON missing — telegram never configured"
    fi

    # 6. tmux/screen backend
    if command -v tmux >/dev/null 2>&1; then
      g "tmux available (preferred backend)"
    elif command -v screen >/dev/null 2>&1; then
      y "tmux not installed; falling back to screen"
    else
      r "neither tmux nor screen installed — bot can't run detached"
    fi

    # 7. locale (Codex P1, prevents Cyrillic mojibake)
    LOC="${LANG}${LC_ALL}${LC_CTYPE}"
    if echo "$LOC" | grep -qi "utf"; then
      g "locale is UTF-8 (LANG=$LANG)"
    else
      y "locale not UTF-8 (LANG=$LANG) — bot's start.sh forces it, but your shell may show mojibake"
    fi

    # 8. session running
    if (tmux list-sessions 2>/dev/null | grep -q mavka) || \
       (screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'); then
      g "MavKa session is running"
    else
      y "no running MavKa session (try: mavka start)"
    fi

    # 9. /telegram-status polling check (only if pi+session are healthy)
    if command -v pi >/dev/null 2>&1 && (tmux list-sessions 2>/dev/null | grep -q mavka); then
      tmux send-keys -t mavka "/telegram-status" Enter 2>/dev/null && sleep 2
      OUT=$(tmux capture-pane -pt mavka -S -50 2>/dev/null)
      if echo "$OUT" | grep -qE "polling|connected|running"; then
        g "telegram bridge reports active (/telegram-status: polling/connected)"
      elif [ -n "$OUT" ]; then
        y "/telegram-status did not show 'polling' — bridge may not be live yet"
      fi
    fi

    # 10. LaunchAgent / systemd unit
    if [ -f "$HOME/Library/LaunchAgents/com.mavka.bot.plist" ]; then
      if launchctl list 2>/dev/null | grep -q com.mavka.bot; then
        g "LaunchAgent loaded (autostart enabled)"
      else
        y "LaunchAgent plist exists but not loaded — autostart off until next install verifies launch"
      fi
    elif [ -f "$HOME/.config/systemd/user/mavka.service" ]; then
      if systemctl --user is-enabled mavka 2>/dev/null | grep -q enabled; then
        g "systemd unit enabled (autostart on)"
      else
        y "systemd unit exists but not enabled — autostart off"
      fi
    fi

    echo ""
    echo "Result: $PASS ok, $WARN warn, $FAIL fail"
    [ "$FAIL" -gt 0 ] && exit 1 || exit 0
    ;;
  uninstall)
    "$0" stop
    if [ -f "$HOME/Library/LaunchAgents/com.mavka.bot.plist" ]; then
      rm -f "$HOME/Library/LaunchAgents/com.mavka.bot.plist"
    fi
    if [ -f "$HOME/.config/systemd/user/mavka.service" ]; then
      systemctl --user disable mavka 2>/dev/null
      rm -f "$HOME/.config/systemd/user/mavka.service"
    fi
    echo "MavKa uninstalled. Files in $MAVKA_HOME remain — remove manually if desired."
    ;;
  -h|--help|help)
    cat <<USAGE
MavKa 🍃 — control commands

  mavka              chat with the bot in this terminal
  mavka start        start the bot (foreground/screen autostart)
  mavka stop         stop the bot
  mavka restart      stop + start
  mavka logs         tail mavka.log
  mavka status       running / stopped
  mavka doctor       full health check (pi, telegram, locale, autostart)
  mavka uninstall    remove autostart (files stay)
  mavka help         this message
USAGE
    ;;
  *)
    echo "Unknown action: $ACTION (try \`mavka help\`)"
    exit 1
    ;;
esac
MAVKAEOF
  chmod +x "$MAVKA_HOME/mavka"
  ok "mavka CLI created"

  # Try to wire `mavka` into PATH so the user can type it from anywhere.
  # Prefer a symlink in /usr/local/bin (no PATH edits, no shell-rc edits)
  # if the dir is writable; fall back to a hint.
  if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    ln -sfn "$MAVKA_HOME/mavka" /usr/local/bin/mavka 2>/dev/null && \
      ok "linked /usr/local/bin/mavka → ~/mavka-bot/mavka"
  else
    # Always try ~/.local/bin — create it if it doesn't exist (common on
    # fresh systems). This is the canonical user-local binary location
    # on Linux + per recent macOS conventions.
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$MAVKA_HOME/mavka" "$HOME/.local/bin/mavka" 2>/dev/null && \
      ok "linked ~/.local/bin/mavka → ~/mavka-bot/mavka"
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) info "Add this to your shell rc so \`mavka\` works from anywhere: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
    esac
  fi

  # ── search.sh ──
  cat > "$MAVKA_HOME/search.sh" << 'SEARCHEOF'
#!/bin/bash
QUERY="$1"; MAX="${2:-5}"
TAVILY_KEY="${TAVILY_API_KEY}"
[ -z "$QUERY" ] && { echo "Usage: search.sh \"query\" [max]"; exit 1; }
[ -z "$TAVILY_KEY" ] && { echo "Error: TAVILY_API_KEY not set"; exit 1; }

# Build JSON via python so quotes/backslashes/newlines in $QUERY are escaped properly
PAYLOAD=$(TAVILY_KEY="$TAVILY_KEY" QUERY="$QUERY" MAX="$MAX" python3 - <<'PYEOF'
import json, os
print(json.dumps({
    "api_key": os.environ["TAVILY_KEY"],
    "query":   os.environ["QUERY"],
    "search_depth": "advanced",
    "include_answer": True,
    "max_results": int(os.environ.get("MAX", "5")),
}))
PYEOF
)
RESULT=$(curl -s -X POST "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null)

if echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);exit(0 if d.get('results') else 1)" 2>/dev/null; then
  echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('answer'): print(d['answer']); print()
for i,r in enumerate(d.get('results',[]),1):
    print(f'{i}. {r.get(\"title\",\"\")}')
    print(f'   {r.get(\"url\",\"\")}')
    if r.get('content'): print(f'   {r[\"content\"][:300]}')
    print()
"
else
  python3 -c "
from duckduckgo_search import DDGS
import sys
for i,r in enumerate(DDGS().text(sys.argv[1],max_results=int(sys.argv[2])),1):
    print(f'{i}. {r[\"title\"]}'); print(f'   {r[\"href\"]}'); print(f'   {r[\"body\"]}'); print()
" "$QUERY" "$MAX" 2>/dev/null || echo "Search failed"
fi
SEARCHEOF
  chmod +x "$MAVKA_HOME/search.sh"

  # ── whisper.sh ──
  # Two modes:
  #   normal:   transcribe audio in its native language (auto-detect)
  #   --british: translate ANY language → English natively via Groq /translations
  #              (no LLM step — Whisper itself does the translation)
  cat > "$MAVKA_HOME/whisper.sh" << 'WHISPEREOF'
#!/bin/bash
AUDIO="$1"
MODE="${2:-normal}"
[ -z "$AUDIO" ] || [ ! -f "$AUDIO" ] && { echo "Error: audio file not found"; exit 1; }
GROQ_KEY="${GROQ_API_KEY}"
[ -z "$GROQ_KEY" ] && { echo "Error: GROQ_API_KEY not set"; exit 1; }

EXT="${AUDIO##*.}"; TMP="/tmp/mavka_whisper.${EXT}"
cp "$AUDIO" "$TMP"
[[ "$EXT" == "oga" ]] && { mv "$TMP" "/tmp/mavka_whisper.ogg"; TMP="/tmp/mavka_whisper.ogg"; }

if [ "$MODE" == "--british" ]; then
  # British mode: any language → English (Whisper native translation)
  curl -s -X POST 'https://api.groq.com/openai/v1/audio/translations' \
    -H "Authorization: Bearer $GROQ_KEY" \
    -F "file=@$TMP" -F 'model=whisper-large-v3' -F 'response_format=text'
else
  # Normal: transcribe in native language (no language hint = auto-detect)
  curl -s -X POST 'https://api.groq.com/openai/v1/audio/transcriptions' \
    -H "Authorization: Bearer $GROQ_KEY" \
    -F "file=@$TMP" -F 'model=whisper-large-v3' -F 'response_format=text'
fi
rm -f "$TMP" 2>/dev/null
WHISPEREOF
  chmod +x "$MAVKA_HOME/whisper.sh"

  # ── setkey.sh — change API key via Telegram, no reinstall needed ──
  # Usage: bash ~/mavka-bot/setkey.sh <provider> <new_key>
  # Provider names: deepseek | openai | anthropic | moonshotai | groq | google | tavily
  cat > "$MAVKA_HOME/setkey.sh" << 'SETKEYEOF'
#!/bin/bash
# Update an API key in MavKa's config and restart the bot.
# Used when the user wants to swap providers or rotate a key without reinstalling.
PROV="$1"
NEWKEY="$2"

if [ -z "$PROV" ] || [ -z "$NEWKEY" ]; then
  cat <<USAGE
Usage: bash ~/mavka-bot/setkey.sh <provider> <new_key>

Providers (LLM):       deepseek, openai, anthropic, moonshotai, groq
Providers (tools):     google (Gemini), tavily (search), groq (also voice)

Example:
  bash ~/mavka-bot/setkey.sh deepseek sk-newkey...
USAGE
  exit 1
fi

case "$PROV" in
  deepseek|openai|anthropic|moonshotai|groq|google)
    AUTH="$HOME/.pi/agent/auth.json"
    [ -f "$AUTH" ] || { echo "Error: $AUTH not found"; exit 1; }
    AUTH_OUT="$AUTH" PROV="$PROV" NEWKEY="$NEWKEY" python3 - <<'PYEOF'
import json, os
path = os.environ['AUTH_OUT']
with open(path) as f: auth = json.load(f)
auth[os.environ['PROV']] = {'type':'api_key','key':os.environ['NEWKEY']}
with open(path, 'w') as f: json.dump(auth, f, indent=2)
os.chmod(path, 0o600)
print(f"✓ {os.environ['PROV']} key updated in auth.json")
PYEOF
    ;;
  tavily)
    # Tavily key is exported as env var in start.sh — patch that line
    START="$HOME/mavka-bot/start.sh"
    [ -f "$START" ] || { echo "Error: $START not found"; exit 1; }
    if grep -q '^export TAVILY_API_KEY=' "$START"; then
      sed -i.bak "s|^export TAVILY_API_KEY=.*|export TAVILY_API_KEY=\"$NEWKEY\"|" "$START"
    else
      echo "export TAVILY_API_KEY=\"$NEWKEY\"" >> "$START"
    fi
    rm -f "${START}.bak"
    chmod 700 "$START"
    echo "✓ tavily key updated in start.sh"
    ;;
  *)
    echo "Error: unknown provider '$PROV'"
    echo "Allowed: deepseek, openai, anthropic, moonshotai, groq, google, tavily"
    exit 1
    ;;
esac

# Restart the bot so the new key takes effect.
# Kill EVERY copy of the agent, not just one tmux session — old pi processes
# cache auth.json in memory and would keep using the old key otherwise.
echo "Restarting MavKa..."
tmux kill-session -t mavka >/dev/null 2>&1 || true
screen -ls 2>/dev/null | awk '/^[[:space:]]*[0-9]+\.mavka[[:space:]]/{print $1}' | xargs -I{} screen -S {} -X quit >/dev/null 2>&1 || true
screen -wipe >/dev/null 2>&1 || true
pkill -f 'mavka-bot/start\.sh' >/dev/null 2>&1 || true
pkill -f 'pi --provider'      >/dev/null 2>&1 || true
sleep 2

# Prefer the autostart unit (it survived reboots; wins over manual launch)
if launchctl list 2>/dev/null | grep -q com.mavka.bot; then
  launchctl kickstart -k "gui/$UID/com.mavka.bot" >/dev/null 2>&1 || true
elif systemctl --user is-active mavka >/dev/null 2>&1; then
  systemctl --user restart mavka >/dev/null 2>&1 || true
elif [ -x "$HOME/mavka-bot/launch.sh" ]; then
  bash "$HOME/mavka-bot/launch.sh" &>/dev/null &
fi

echo "✓ MavKa restarted. New key is live."
SETKEYEOF
  chmod +x "$MAVKA_HOME/setkey.sh"

  # ── tts.sh ──
  cat > "$MAVKA_HOME/tts.sh" << 'TTSEOF'
#!/bin/bash
TEXT="$1"; OUTPUT="${2:-/tmp/mavka-voice.ogg}"
[ -z "$TEXT" ] && { echo "Usage: tts.sh \"text\" [output]"; exit 1; }
edge-tts --voice "en-US-AriaNeural" --text "$TEXT" --write-media "$OUTPUT" 2>/dev/null && echo "$OUTPUT" || \
{ echo "Error: TTS failed"; exit 1; }
TTSEOF
  chmod +x "$MAVKA_HOME/tts.sh"

  # ── token.sh — context-usage indicator (two-tone thermometer) ──
  # Triggered from IDENTITY when the user types the standalone word "токен" /
  # "token". Reads the most recent Pi Agent session JSONL, sums message
  # usage, renders a 10-block bar in the load colour (green/yellow/orange/red)
  # plus a Gilfoyle-deadpan one-liner per cube count in the user's language.
  # Output is two lines: backtick-wrapped bar + counters, then the phrase.
  cat > "$MAVKA_HOME/token.sh" << 'TOKENEOF'
#!/bin/bash
# MavKa token statusline. Two-line output:
#   line 1:  `<bar> <K>K/200K`         (in single backticks for monospace)
#   line 2:  <phrase tied to cube count>
LANG_CODE="__LANG__"
LIMIT=200000

LATEST=$(ls -t "$HOME/.pi/agent/sessions"/*mavka-bot*/*.jsonl 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
    TOTAL=0
else
    TOTAL=$(python3 - "$LATEST" <<'PYEOF'
import json, sys
total = 0
try:
    with open(sys.argv[1]) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            usage = (obj.get("message") or {}).get("usage") or {}
            total += int(usage.get("input") or 0) + int(usage.get("output") or 0)
except FileNotFoundError:
    pass
print(total)
PYEOF
)
fi
[ -z "$TOTAL" ] && TOTAL=0

PCT=$(( TOTAL * 100 / LIMIT ))
[ "$PCT" -gt 100 ] && PCT=100
BLOCKS=$(( PCT / 10 ))
[ "$BLOCKS" -lt 0 ] && BLOCKS=0
[ "$BLOCKS" -gt 10 ] && BLOCKS=10

# Two-tone bar: every filled cube is the same colour, every empty cube ⬛.
# Colour by cube count: 0-2 green, 3-5 yellow, 6-8 orange, 9-10 red.
if   [ "$BLOCKS" -le 2 ]; then FILL='🟩'
elif [ "$BLOCKS" -le 5 ]; then FILL='🟨'
elif [ "$BLOCKS" -le 8 ]; then FILL='🟧'
else                            FILL='🟥'
fi

BAR=$(python3 -c "print('${FILL}' * $BLOCKS + '⬛' * (10 - $BLOCKS))")
TK=$(( TOTAL / 1000 ))

# Phrase index: 0..10 mapped to cube count, 11 reserved for overflow.
if [ "$TOTAL" -gt "$LIMIT" ]; then
    IDX=11
else
    IDX="$BLOCKS"
fi

# Gilfoyle-deadpan one-liners, indexed [0..11], in the install language.
case "$LANG_CODE" in
ru)
    PHRASES=(
        "Редкая форма невинности"
        "Пока никто не облажался. Настораживает"
        "Слишком спокойно. Где подвох?"
        "Начинается управляемая деградация"
        "Половина памяти ушла на чью-то «гениальную» идею"
        "Уже пахнет горячим кремнием и плохими решениями"
        "Оранжевый уровень. Кто-то трогал прод в пятницу"
        "RAM держится на кофеине и сексуальном напряжении"
        "Система стонет, но HR просил это так не называть"
        "Контекст держится чисто из ненависти"
        "Отличный момент обвинить инфраструктуру и исчезнуть"
        "Я предупреждала. Но люди всегда думают членом, а не логами"
    )
    ;;
uk)
    PHRASES=(
        "Рідкісна форма невинності"
        "Поки ніхто не облажався. Насторожує"
        "Занадто тихо. Де підступ?"
        "Починається керована деградація"
        "Половина памʼяті пішла на чиюсь «геніальну» ідею"
        "Вже пахне гарячим кремнієм і поганими рішеннями"
        "Помаранчевий рівень. Хтось чіпав прод у пʼятницю"
        "RAM тримається на кофеїні й сексуальному напруженні"
        "Система стогне, але HR просив це так не називати"
        "Контекст тримається суто з ненависті"
        "Чудовий момент звинуватити інфраструктуру і зникнути"
        "Я попереджала. Але люди завжди думають членом, а не логами"
    )
    ;;
de)
    PHRASES=(
        "Eine seltene Form der Unschuld"
        "Noch hat's keiner versemmelt. Verdächtig"
        "Zu ruhig. Wo ist der Haken?"
        "Kontrollierte Degradation beginnt"
        "Die Hälfte vom RAM ging für jemandes «geniale» Idee drauf"
        "Riecht schon nach heißem Silizium und schlechten Entscheidungen"
        "Orange-Stufe. Jemand hat freitags an Prod rumgespielt"
        "RAM hält nur dank Koffein und sexueller Spannung"
        "Das System ächzt, aber HR will, dass wir es anders nennen"
        "Kontext hält rein aus Trotz"
        "Perfekter Moment, der Infrastruktur die Schuld zu geben und zu verschwinden"
        "Ich hab gewarnt. Aber die Leute denken immer mit dem Schwanz, nicht mit den Logs"
    )
    ;;
fr)
    PHRASES=(
        "Une rare forme d'innocence"
        "Personne n'a encore foiré. Suspect"
        "Trop calme. Où est le piège?"
        "La dégradation contrôlée commence"
        "La moitié de la RAM est partie dans «l'idée géniale» de quelqu'un"
        "Ça sent déjà le silicium chaud et les mauvaises décisions"
        "Niveau orange. Quelqu'un a touché à la prod un vendredi"
        "La RAM tient grâce à la caféine et la tension sexuelle"
        "Le système gémit, mais les RH ont demandé de ne pas dire ça comme ça"
        "Le contexte tient uniquement par dépit"
        "Moment parfait pour accuser l'infrastructure et disparaître"
        "Je t'avais prévenu. Mais les gens pensent toujours avec leur bite, pas avec leurs logs"
    )
    ;;
es)
    PHRASES=(
        "Una rara forma de inocencia"
        "Nadie la ha jodido aún. Sospechoso"
        "Demasiado tranquilo. ¿Dónde está la trampa?"
        "Empieza la degradación controlada"
        "La mitad de la RAM se fue en la idea «genial» de alguien"
        "Ya huele a silicio caliente y a malas decisiones"
        "Nivel naranja. Alguien tocó producción un viernes"
        "La RAM se sostiene a base de cafeína y tensión sexual"
        "El sistema gime, pero RR.HH. pidió que no lo llamemos así"
        "El contexto se mantiene puramente por rencor"
        "Momento perfecto para echar la culpa a la infraestructura y desaparecer"
        "Te lo advertí. Pero la gente siempre piensa con la polla, no con los logs"
    )
    ;;
*)
    PHRASES=(
        "A rare form of innocence"
        "Nobody has screwed up yet. Suspicious"
        "Too quiet. Where's the catch?"
        "Controlled degradation begins"
        "Half the RAM went to someone's \"brilliant\" idea"
        "Already smells like hot silicon and bad decisions"
        "Orange level. Somebody touched prod on a Friday"
        "RAM is held together by caffeine and sexual tension"
        "The system is groaning, but HR asked us not to call it that"
        "Context held purely out of spite"
        "Perfect moment to blame infrastructure and vanish"
        "I warned you. But people always think with their dick, not their logs"
    )
    ;;
esac

PHRASE="${PHRASES[$IDX]}"

echo "${BAR} ${TK}K/200K"
echo "${PHRASE}"
TOKENEOF
  # Bake the user's chosen install language into the script.
  sed -i.bak "s|__LANG__|${BOT_LANG}|" "$MAVKA_HOME/token.sh"
  rm -f "$MAVKA_HOME/token.sh.bak"
  chmod +x "$MAVKA_HOME/token.sh"

  # ── vision.sh ──
  cat > "$MAVKA_HOME/vision.sh" << 'VISIONEOF'
#!/bin/bash
IMAGE_PATH="$1"
QUESTION="${2:-Describe this image in detail. If there is text, transcribe it fully.}"
[ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ] && { echo "Error: file not found"; exit 1; }
API_KEY="${GEMINI_API_KEY}"
[ -z "$API_KEY" ] && { echo "Error: GEMINI_API_KEY not set"; exit 1; }
MIME_TYPE=$(file --mime-type -b "$IMAGE_PATH")
case "$MIME_TYPE" in image/jpeg|image/png|image/gif|image/webp) ;; *) MIME_TYPE="image/jpeg" ;; esac
BASE64_IMAGE=$(base64 -i "$IMAGE_PATH" 2>/dev/null || base64 -w0 "$IMAGE_PATH" 2>/dev/null)
python3 -c "
import json
data={'contents':[{'parts':[{'text':'''$QUESTION'''},{'inline_data':{'mime_type':'$MIME_TYPE','data':'''$BASE64_IMAGE'''}}]}],'generationConfig':{'temperature':0.2,'maxOutputTokens':2048}}
with open('/tmp/mavka_vision.json','w') as f: json.dump(data,f)
"
for MODEL in gemini-2.5-flash gemini-2.5-flash-lite; do
  RESULT=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=$API_KEY" \
    -H "Content-Type: application/json" -d @/tmp/mavka_vision.json)
  TEXT=$(echo "$RESULT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if 'candidates' in d: print(d['candidates'][0]['content']['parts'][0]['text'])
    else: print('')
except: print('')
" 2>/dev/null)
  [ -n "$TEXT" ] && { echo "$TEXT"; exit 0; }
done
echo "Error: vision failed"; exit 1
VISIONEOF
  chmod +x "$MAVKA_HOME/vision.sh"

  ok "Tools created (search, whisper, tts, vision)"

  # ── Memory wiki lint script ──
  # Run manually or schedule weekly via launchd/systemd:
  #   bash ~/mavka-bot/lint.sh
  cat > "$MAVKA_HOME/lint.sh" << 'LINTEOF'
#!/bin/bash
# MavKa memory wiki lint — finds orphans, broken cross-links, stale pages.
MEM="$HOME/mavka-bot/memory"
[ -d "$MEM" ] || { echo "no memory dir"; exit 1; }

echo "== Memory wiki lint =="
echo

cd "$MEM" || exit 1

# Collect all .md files in memory/ (excluding raw/ and summaries/)
# NUL-delimited so filenames with spaces work
files=()
while IFS= read -r -d '' f; do
  files+=("${f#./}")
done < <(find . -maxdepth 1 -name '*.md' -not -name 'MEMORY.md' -not -name 'log.md' -print0)

# Orphans: files not referenced from MEMORY.md
echo "-- Orphans (files not listed in MEMORY.md) --"
for f in "${files[@]}"; do
  if ! grep -qF "$f" MEMORY.md 2>/dev/null; then
    echo "  orphan: $f"
  fi
done
echo

# Broken cross-links: [[file.md]] referenced but file missing
echo "-- Broken cross-links --"
grep -roh '\[\[[^]]*\]\]' --include='*.md' . 2>/dev/null | sort -u | while read link; do
  target=$(echo "$link" | sed 's/\[\[//;s/\]\]//')
  [ -f "$target" ] || echo "  broken: $link"
done
echo

# Stale: pages with valid_from older than 60 days and no recent activity in log.md
echo "-- Stale pages (valid_from > 60 days, no recent INGEST in log) --"
NOW=$(date +%s)
for f in "${files[@]}"; do
  vf=$(grep -m1 '^valid_from:' "$f" 2>/dev/null | awk '{print $2}')
  [ -n "$vf" ] || continue
  vf_s=$(date -j -f "%Y-%m-%d" "$vf" +%s 2>/dev/null || date -d "$vf" +%s 2>/dev/null)
  [ -n "$vf_s" ] || continue
  age=$(( (NOW - vf_s) / 86400 ))
  if [ "$age" -gt 60 ]; then
    if ! grep -qF "$f" log.md 2>/dev/null; then
      echo "  stale: $f (valid_from $vf, age ${age}d, never touched in log)"
    fi
  fi
done
echo

echo "-- Summary --"
echo "  pages: ${#files[@]}"
echo "  index size: $(wc -l < MEMORY.md | tr -d ' ') lines"
echo "  log entries: $(grep -c '|' log.md 2>/dev/null || echo 0)"
LINTEOF
  chmod +x "$MAVKA_HOME/lint.sh"

  # ── recall.sh — agent-callable retrieval over memory wiki + history ──
  # Usage: bash ~/mavka-bot/recall.sh "query" [max=20]
  cat > "$MAVKA_HOME/recall.sh" << 'RECALLEOF'
#!/bin/bash
# Search MavKa's long-term memory and conversation history for a query.
# Returns up to N matches across:
#   - memory wiki pages (~/mavka-bot/memory/*.md)
#   - chat history (~/mavka-bot/history/*.jsonl)
#   - distilled summaries (~/mavka-bot/memory/summaries/*.md)
QUERY="$*"
MAX="${MAX:-20}"
[ -z "$QUERY" ] && { echo "Usage: recall.sh \"search query\""; exit 1; }

MEM="$HOME/mavka-bot/memory"
HIST="$HOME/mavka-bot/history"

echo "== recall: $QUERY =="
echo

# 1. Memory wiki — case-insensitive grep with surrounding context
if [ -d "$MEM" ]; then
  echo "-- memory wiki --"
  grep -rli --include='*.md' -m 1 "$QUERY" "$MEM" 2>/dev/null | head -10 | while read -r f; do
    rel="${f#$HOME/}"
    echo "[$rel]"
    grep -n -i -B1 -A2 "$QUERY" "$f" 2>/dev/null | head -8
    echo
  done
fi

# 2. Chat history — JSONL files, search across last 30 days
if [ -d "$HIST" ]; then
  echo "-- chat history (last 30 days) --"
  find "$HIST" -name '*.jsonl' -mtime -30 2>/dev/null | sort -r | while read -r f; do
    matches=$(grep -i "$QUERY" "$f" 2>/dev/null | head -3)
    if [ -n "$matches" ]; then
      echo "[$(basename "$f" .jsonl)]"
      echo "$matches" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line)
        role = d.get('role','?')
        text = d.get('text','')[:200]
        ts = d.get('ts','')
        print(f'  {ts} {role}: {text}')
    except: pass
" 2>/dev/null
      echo
    fi
  done | head -40
fi

# 3. Summaries
if [ -d "$MEM/summaries" ]; then
  echo "-- distilled summaries --"
  grep -rli "$QUERY" "$MEM/summaries" 2>/dev/null | head -5 | while read -r f; do
    rel="${f#$HOME/}"
    echo "[$rel]"
    grep -n -i -B1 -A2 "$QUERY" "$f" 2>/dev/null | head -5
    echo
  done
fi
RECALLEOF
  chmod +x "$MAVKA_HOME/recall.sh"

  # ── distill.sh — weekly: summarize old chat history → summaries/ ──
  cat > "$MAVKA_HOME/distill.sh" << 'DISTILLEOF'
#!/bin/bash
# Distill chat history older than 30 days into weekly summaries.
# Schedule weekly: cron / launchd / systemd.
HIST="$HOME/mavka-bot/history"
SUM="$HOME/mavka-bot/memory/summaries"
mkdir -p "$SUM"

# Source API key from start.sh's environment so we can call the LLM
[ -f "$HOME/mavka-bot/start.sh" ] && source <(grep -E '^export (DEEPSEEK|OPENAI|ANTHROPIC|GROQ|MOONSHOT)_API_KEY' "$HOME/mavka-bot/start.sh")

[ -d "$HIST" ] || exit 0

# Find jsonl files older than 30 days that haven't been distilled yet
find "$HIST" -name '*.jsonl' -mtime +30 2>/dev/null | sort | while read -r f; do
  date_tag=$(basename "$f" .jsonl)
  out="$SUM/${date_tag}.md"
  [ -f "$out" ] && continue   # already distilled

  # Concatenate up to 200 messages
  raw=$(head -200 "$f" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line)
        print(f\"[{d.get('role','?')}] {d.get('text','')[:300]}\")
    except: pass
" 2>/dev/null)
  [ -z "$raw" ] && continue

  # Summarize via the configured AI provider (DeepSeek by default)
  KEY="${DEEPSEEK_API_KEY:-${OPENAI_API_KEY:-}}"
  [ -z "$KEY" ] && { echo "$date_tag — no API key, skipping"; continue; }

  prompt="Summarize this day of Telegram conversation between a user and their AI assistant. Extract: (1) key decisions, (2) facts the user revealed, (3) projects discussed, (4) actions taken. Be terse, factual, no fluff. Output as markdown bullets, max 30 lines.

CONVERSATION:
$raw"

  response=$(curl -s -X POST "https://api.deepseek.com/chat/completions" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
prompt = sys.argv[1]
print(json.dumps({
    'model': 'deepseek-chat',
    'messages': [{'role':'user','content':prompt}],
    'max_tokens': 1500,
    'temperature': 0.3
}))
" "$prompt")")

  text=$(echo "$response" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d['choices'][0]['message']['content'])
except Exception as e:
    sys.exit(1)
" 2>/dev/null)

  if [ -n "$text" ]; then
    cat > "$out" << SUMEOF
---
name: Daily summary $date_tag
description: AI-distilled summary of conversation on $date_tag
type: concept
hall: events
valid_from: $date_tag
---

# Summary — $date_tag

$text

---
*Distilled from $f on $(date +%Y-%m-%d).*
SUMEOF
    echo "$date_tag distilled → summaries/${date_tag}.md"
  fi
done
DISTILLEOF
  chmod +x "$MAVKA_HOME/distill.sh"

  ok "Memory wiki seeded (LLM Wiki Protocol) + lint + recall + distill scripts"
}

# ─── Configure MavKa runtime ──────────────────────────────────
configure_pi() {
  step "Configuring MavKa..."

  # Backup existing config if present
  if [ -f "$HOME/.pi/agent/settings.json" ]; then
    BACKUP_DIR="$HOME/.pi/agent/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.pi/agent/"*.json "$BACKUP_DIR/" 2>/dev/null
    ok "Existing config backed up to $BACKUP_DIR"
  fi

  mkdir -p "$HOME/.pi/agent"

  cat > "$HOME/.pi/agent/telegram.json" << TGJSON
{
  "botToken": "${TG_TOKEN}",
  "allowedUserId": ${TG_USER_ID},
  "lastUpdateId": 0
}
TGJSON

  cat > "$HOME/.pi/agent/settings.json" << PIJSON
{
  "packages": [
    "git:github.com/badlogic/pi-telegram",
    "git:github.com/badlogic/pi-skills"
  ],
  "quietStartup": true,
  "lastChangelogVersion": "99.99.99"
}
PIJSON

  # Build auth.json with all provided keys.
  # IMPORTANT: keys are passed via env vars (NOT bash interpolated into Python source) —
  # prevents code injection if a key contains quotes, backslashes, or $(...).
  AUTH_JSON_OUT="$HOME/.pi/agent/auth.json" \
  AI_KEY="${PROVIDER_KEY:-$DEEPSEEK_KEY}" \
  AI_PROV="${PROVIDER_PI_NAME:-deepseek}" \
  GROQ_KEY="${GROQ_KEY}" \
  GEMINI_KEY="${GEMINI_KEY}" \
  python3 - <<'PYEOF'
import json, os
auth = {}
ai_key   = os.environ.get('AI_KEY', '')
ai_prov  = os.environ.get('AI_PROV', 'deepseek')
groq_key = os.environ.get('GROQ_KEY', '')
gem_key  = os.environ.get('GEMINI_KEY', '')
out_path = os.environ.get('AUTH_JSON_OUT', '')

if ai_key:
    auth[ai_prov] = {'type': 'api_key', 'key': ai_key}
# Groq is also used as a tool (Whisper) — only add as separate entry if it's not the LLM provider
if groq_key and ai_prov != 'groq':
    auth['groq'] = {'type': 'api_key', 'key': groq_key}
if gem_key:
    auth['google'] = {'type': 'api_key', 'key': gem_key}

with open(out_path, 'w') as f:
    json.dump(auth, f, indent=2)
os.chmod(out_path, 0o600)
PYEOF

  # Lock down telegram.json + auth.json (mode 0600 — SECURITY.md claims this)
  # start.sh exports keys, so it stays executable by owner only (0700, not 0600 — needs +x for autostart)
  chmod 600 "$HOME/.pi/agent/telegram.json" "$HOME/.pi/agent/auth.json" 2>/dev/null || true
  [ -f "$MAVKA_HOME/start.sh" ] && chmod 700 "$MAVKA_HOME/start.sh"

  ok "MavKa configured"

  setup_sandbox
}

# ─── Sandbox extension (mitigates Pi's YOLO mode) ─────────────
# Pi Agent has no built-in permissions. Its sandbox extension uses
# sandbox-exec on macOS / bubblewrap on Linux to deny-list secret
# files and restrict network for the `bash` tool.
# https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent/examples/extensions/sandbox
setup_sandbox() {
  step "Setting up Pi sandbox extension..."

  SANDBOX_DIR="$HOME/.pi/agent/extensions/sandbox"
  mkdir -p "$SANDBOX_DIR"

  # Fetch the sandbox extension from pi-mono repo
  if [ ! -f "$SANDBOX_DIR/index.ts" ]; then
    info "Fetching sandbox extension from pi-mono..."
    TMPCLONE=$(mktemp -d)
    if git clone --depth 1 --filter=blob:none --sparse \
        https://github.com/badlogic/pi-mono.git "$TMPCLONE" >/dev/null 2>&1; then
      (cd "$TMPCLONE" && git sparse-checkout set packages/coding-agent/examples/extensions/sandbox >/dev/null 2>&1)
      if [ -d "$TMPCLONE/packages/coding-agent/examples/extensions/sandbox" ]; then
        cp -R "$TMPCLONE/packages/coding-agent/examples/extensions/sandbox/." "$SANDBOX_DIR/" 2>/dev/null
      fi
      rm -rf "$TMPCLONE"
    fi
    # Install npm deps if package.json present
    if [ -f "$SANDBOX_DIR/package.json" ]; then
      (cd "$SANDBOX_DIR" && npm install --silent --no-audit --no-fund >/dev/null 2>&1) || \
        warn "Sandbox npm install failed — sandbox may not load"
    fi
  fi

  # Sanity-check: the upstream sandbox example imports
  # `@earendil-works/pi-coding-agent` (the new package name), but the
  # globally-installed Pi we use is published under
  # `@mariozechner/pi-coding-agent`. Until upstream resolves the rename,
  # the sandbox extension fails to load and CRASHES Pi at startup
  # ("Cannot find module '@earendil-works/pi-coding-agent'"), which means
  # the user's bot never comes up.
  #
  # Detect the mismatch and disable the extension by removing the index.ts
  # so Pi skips it gracefully. Users who want sandbox can re-enable later
  # once the package names align.
  if [ -f "$SANDBOX_DIR/index.ts" ] && \
     grep -q "@earendil-works/pi-coding-agent" "$SANDBOX_DIR/index.ts" 2>/dev/null && \
     ! [ -d "$SANDBOX_DIR/node_modules/@earendil-works/pi-coding-agent" ]; then
    warn "Pi sandbox extension imports a package not present in this Pi build — disabling sandbox to keep the bot working."
    info "Remove $SANDBOX_DIR if you want a clean state. Re-enable manually when upstream pi-mono aligns scopes."
    mv "$SANDBOX_DIR/index.ts" "$SANDBOX_DIR/index.ts.disabled" 2>/dev/null || rm -f "$SANDBOX_DIR/index.ts"
  fi

  # Default deny-list config
  cat > "$HOME/.pi/agent/extensions/sandbox.json" << SANDBOXJSON
{
  "enabled": true,
  "network": {
    "allowedDomains": ["*"],
    "deniedDomains": []
  },
  "filesystem": {
    "denyRead":  ["~/.ssh", "~/.aws", "~/.gnupg", "~/mavka-bot/start.sh", "~/.pi/agent/auth.json", "~/.pi/agent/telegram.json"],
    "allowWrite": [".", "/tmp", "~/mavka-bot"],
    "denyWrite": [".env", ".env.*", "*.pem", "*.key", "id_rsa", "id_ed25519"]
  }
}
SANDBOXJSON

  # Linux: sandbox-runtime needs bubblewrap + socat + ripgrep
  if [ "$OS" = "linux" ]; then
    NEED=""
    command -v bwrap     >/dev/null 2>&1 || NEED="$NEED bubblewrap"
    command -v socat     >/dev/null 2>&1 || NEED="$NEED socat"
    command -v rg        >/dev/null 2>&1 || NEED="$NEED ripgrep"
    if [ -n "$NEED" ]; then
      info "Installing sandbox dependencies:$NEED"
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y $NEED >/dev/null 2>&1 || warn "Sandbox deps install failed — sandbox may be disabled"
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm $NEED >/dev/null 2>&1 || warn "Sandbox deps install failed — sandbox may be disabled"
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y $NEED >/dev/null 2>&1 || warn "Sandbox deps install failed — sandbox may be disabled"
      else
        warn "Could not auto-install $NEED — install manually for sandbox to work."
      fi
    fi
  fi

  if [ "$OS" = "mac" ] || command -v bwrap >/dev/null 2>&1; then
    ok "Sandbox extension configured (deny-list applied)"
    SANDBOX_ENABLED=1
  else
    warn "Sandbox unavailable on this system — Pi will run with full file/network access"
    SANDBOX_ENABLED=0
  fi
}

# ─── Patch pi-telegram ────────────────────────────────────────
patch_telegram() {
  step "Patching Telegram extension..."

  PI_TG="$HOME/.pi/agent/git/github.com/badlogic/pi-telegram/index.ts"

  if [ ! -f "$PI_TG" ]; then
    info "Pi-telegram not yet installed, will be fetched on first run."
    info "Run the bot once, then re-run: bash ~/mavka-bot/patch.sh"

    cat > "$MAVKA_HOME/patch.sh" << 'PATCHEOF'
#!/bin/bash
# MavKa 🍃 — Patch pi-telegram for auto-connect + HTML formatting
set -e
PI_TG="$HOME/.pi/agent/git/github.com/badlogic/pi-telegram/index.ts"
[ ! -f "$PI_TG" ] && { echo "Error: pi-telegram not found. Run the bot first."; exit 1; }

python3 << 'PYEOF'
import re, sys

path = __import__("os").path.expanduser("~/.pi/agent/git/github.com/badlogic/pi-telegram/index.ts")
with open(path, "r") as f:
    content = f.read()

changes = 0

# 1. Fix bold regex: [^*]+ → [\s\S]+? (handles nested * inside **)
old_bold = r'html = html.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");'
new_bold = r'html = html.replace(/\*\*([\s\S]+?)\*\*/g, "<b>$1</b>");'
if old_bold in content:
    content = content.replace(old_bold, new_bold)
    changes += 1
    print("✓ Fixed bold regex")

# 2. Auto-connect on session_start.
#
# Upstream pi-telegram already has a session_start handler. The old patch
# only acted when it was *absent*, which silently no-op'd on current
# upstream → no auto-connect → bridge stayed dependent on a fragile typed
# /telegram-connect that may fire before Pi is ready.
#
# New behaviour:
#  - if a session_start handler exists AND already calls startPolling → done
#  - if session_start exists but does NOT call startPolling → inject the
#    `if (config.botToken) { await startPolling(ctx); ... }` block at the
#    end of the handler body
#  - if session_start does NOT exist → insert a fresh handler before
#    session_end (legacy path)
#  - if neither pattern is present → fail loudly so we don't silently ship
#    a broken bridge
session_start_re = re.compile(
    r'(pi\.on\("session_start",\s*async\s*\([^)]*\)\s*=>\s*\{)([\s\S]*?)(\n\s*\}\);)',
    re.MULTILINE,
)
m = session_start_re.search(content)
if m:
    head, body, tail = m.group(1), m.group(2), m.group(3)
    if "startPolling" in body:
        print("✓ session_start already calls startPolling — no patch needed")
    else:
        # Inject the auto-connect block at the end of the handler body.
        # Match the indentation of the handler's existing body lines.
        indent = "\t\t"
        m_indent = re.search(r'\n([ \t]+)\S', body)
        if m_indent:
            indent = m_indent.group(1)
        injection = (
            f"\n{indent}if (config && config.botToken) {{\n"
            f"{indent}\tawait startPolling(ctx);\n"
            f"{indent}\tupdateStatus(ctx);\n"
            f"{indent}}}"
        )
        new_body = body.rstrip() + injection
        content = content.replace(m.group(0), head + new_body + tail, 1)
        changes += 1
        print("✓ Injected startPolling into existing session_start handler")
else:
    # Legacy fallback: insert a fresh session_start before session_end.
    session_end_match = re.search(r'pi\.on\("session_end"', content)
    if session_end_match:
        insert_pos = session_end_match.start()
        auto_connect = '''pi.on("session_start", async (_event, ctx) => {
\t\tconfig = await readConfig();
\t\tawait mkdir(TEMP_DIR, { recursive: true });
\t\tupdateStatus(ctx);
\t\tif (config.botToken) {
\t\t\tawait startPolling(ctx);
\t\t\tupdateStatus(ctx);
\t\t}
\t\tif ((ctx as any).ui && typeof (ctx as any).ui.setWorkingIndicator === 'function') {
\t\t\t(ctx as any).ui.setWorkingIndicator({
\t\t\t\tframes: ['🍃     ', ' 🍃    ', '  🍃   ', '   🍃  ', '    🍃 ', '     🍃', '    🍃 ', '   🍃  ', '  🍃   ', ' 🍃    '],
\t\t\t\tintervalMs: 180,
\t\t\t});
\t\t}
\t});

\t'''
        content = content[:insert_pos] + auto_connect + content[insert_pos:]
        changes += 1
        print("✓ Added fresh session_start handler with auto-connect")
    else:
        print("⚠ FAIL: neither session_start nor session_end found in pi-telegram — upstream API changed; manual patch required")
        sys.exit(2)

# 3. Drop the visible "[telegram]" prefix on every incoming Telegram
# message — Olesya called it "stupid because it's obvious". We replace
# the constant with a zero-width space (U+200B): invisible to the user,
# still present for the isTelegramPrompt() routing check that decides
# whether to add the "this message came from Telegram" suffix to the
# system prompt. Idempotent: only changes the line that's still the
# original "[telegram]" form.
old_prefix = 'const TELEGRAM_PREFIX = "[telegram]";'
new_prefix = 'const TELEGRAM_PREFIX = "\\u200B";'
if old_prefix in content:
    content = content.replace(old_prefix, new_prefix, 1)
    changes += 1
    print("✓ Hid the [telegram] prefix (now zero-width)")
elif new_prefix in content:
    print("✓ [telegram] prefix already hidden — no patch needed")
else:
    print("⚠ TELEGRAM_PREFIX line not in expected form — skipping prefix hide")

# 4. MavKa 🍃 brand spinner — replace pi's default braille spinner
# (⠋⠙⠹...) with leaf bouncing left-right. Runs INDEPENDENTLY of
# the startPolling injection above so it works even when session_start
# already calls startPolling on its own. Idempotent — only injects
# if "setWorkingIndicator" is not already present.
if "setWorkingIndicator" not in content:
    m2 = session_start_re.search(content)
    if m2:
        head2, body2, tail2 = m2.group(1), m2.group(2), m2.group(3)
        indent2 = "\t\t"
        m_indent2 = re.search(r'\n([ \t]+)\S', body2)
        if m_indent2:
            indent2 = m_indent2.group(1)
        spinner_block = (
            f"\n{indent2}if ((ctx as any).ui && typeof (ctx as any).ui.setWorkingIndicator === 'function') {{\n"
            f"{indent2}\t(ctx as any).ui.setWorkingIndicator({{\n"
            f"{indent2}\t\tframes: ['🍃     ', ' 🍃    ', '  🍃   ', '   🍃  ', '    🍃 ', '     🍃', '    🍃 ', '   🍃  ', '  🍃   ', ' 🍃    '],\n"
            f"{indent2}\t\tintervalMs: 180,\n"
            f"{indent2}\t}});\n"
            f"{indent2}}}"
        )
        new_body2 = body2.rstrip() + spinner_block
        content = content.replace(m2.group(0), head2 + new_body2 + tail2, 1)
        changes += 1
        print("✓ Injected MavKa leaf spinner into session_start")
    else:
        print("⚠ session_start not found — skipping spinner branding")
else:
    print("✓ MavKa spinner already installed — no patch needed")

# 5. Check if markdownToTelegramHtml exists
if "markdownToTelegramHtml" not in content:
    print("⚠ markdownToTelegramHtml not found — this version may need manual patching")
else:
    print("✓ markdownToTelegramHtml present")

if changes > 0:
    with open(path, "w") as f:
        f.write(content)
    # Clear jiti cache
    import glob, os
    for f in glob.glob("/tmp/jiti/pi-telegram-index.*.mjs") + \
             glob.glob(os.path.expanduser("~/Library/Caches/jiti/pi-telegram-index.*.mjs")):
        os.remove(f)
        print(f"✓ Cleared jiti cache: {f}")
    for d in ["/var/folders"]:
        for root, dirs, files in os.walk(d):
            for f in files:
                if f.startswith("pi-telegram-index.") and f.endswith(".mjs"):
                    fp = os.path.join(root, f)
                    try:
                        os.remove(fp)
                        print(f"✓ Cleared jiti cache: {fp}")
                    except:
                        pass
            if root.count(os.sep) > 6:
                break
    print(f"\n✓ Applied {changes} patch(es). Restart MavKa to apply.")
else:
    print("\n✓ No patches needed — already up to date.")
PYEOF
PATCHEOF
    chmod +x "$MAVKA_HOME/patch.sh"
    ok "Patch script created (will apply after first run)"
    return
  fi

  bash "$MAVKA_HOME/patch.sh" 2>/dev/null || warn "Patch script had issues, may need manual run"
  ok "Telegram extension patched"
}

# ─── Auto-start Setup ─────────────────────────────────────────
setup_autostart() {
  step "Setting up auto-start..."

  if [ "$OS" = "mac" ]; then
    PLIST_PATH="$HOME/Library/LaunchAgents/com.mavka.bot.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mavka.bot</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${HOME}/mavka-bot/launch.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${HOME}/mavka-bot/mavka.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/mavka-bot/mavka-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${HOME}</string>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${NODE_DIR}:${HOME}/.local/bin</string>
        <key>LANG</key>
        <string>en_US.UTF-8</string>
        <key>LC_ALL</key>
        <string>en_US.UTF-8</string>
        <key>LC_CTYPE</key>
        <string>en_US.UTF-8</string>
    </dict>
</dict>
</plist>
PLISTEOF
    # Unload old version first so re-running the installer doesn't error under set -e.
    # We do NOT load it now — that's deferred to start_with_verification() so we
    # don't race against the explicit launch_bot call (Codex P1 fix).
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    ok "LaunchAgent plist written (deferred load until verified launch)"

  elif [ "$OS" = "linux" ]; then
    SERVICE_PATH="$HOME/.config/systemd/user/mavka.service"
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$SERVICE_PATH" << SVCEOF
[Unit]
Description=MavKa AI Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash ${HOME}/mavka-bot/launch.sh
Restart=on-failure
RestartSec=10
Environment=HOME=${HOME}
Environment=PATH=/usr/local/bin:/usr/bin:/bin:${NODE_DIR}:${HOME}/.local/bin

[Install]
WantedBy=default.target
SVCEOF
    systemctl --user daemon-reload 2>/dev/null || true
    # We do NOT `systemctl --user enable mavka` here — that's deferred to
    # enable_autostart() after launch_bot verifies the unit actually works
    # (Codex P1 fix).
    ok "Systemd unit written (deferred enable until verified launch)"
  fi
}

# ─── First Run (fetch extensions) ─────────────────────────────
first_run() {
  # Codex P0.2 fix: don't bootstrap pi-telegram by *starting and killing*
  # Pi (the old approach raced against npm install / jiti cache / extension
  # init and killed Pi mid-bootstrap on a clean machine — Pi-warmed
  # machines worked because the install was already complete).
  #
  # Instead, deterministically clone pi-telegram + pi-skills directly into
  # Pi's expected git path, then npm install if a package.json is present.
  # patch_telegram() runs on stable code afterwards and the FIRST real Pi
  # launch is the one in launch_bot.
  step "Pre-installing Pi extensions (pi-telegram, pi-skills)..."

  PI_GIT="$HOME/.pi/agent/git/github.com/badlogic"
  mkdir -p "$PI_GIT"

  # pi-telegram — required, hard fail if it doesn't end up present
  if [ -d "$PI_GIT/pi-telegram/.git" ]; then
    ok "pi-telegram already cloned"
  else
    info "cloning pi-telegram..."
    if git clone --depth 1 https://github.com/badlogic/pi-telegram "$PI_GIT/pi-telegram" >/dev/null 2>&1; then
      ok "pi-telegram cloned"
    else
      warn "git clone of pi-telegram failed — will retry once"
      rm -rf "$PI_GIT/pi-telegram"
      git clone https://github.com/badlogic/pi-telegram "$PI_GIT/pi-telegram" >/dev/null 2>&1 || \
        fail "Could not clone pi-telegram. Check network / GitHub access and re-run."
    fi
  fi

  if [ -f "$PI_GIT/pi-telegram/package.json" ] && [ ! -d "$PI_GIT/pi-telegram/node_modules" ]; then
    info "installing pi-telegram dependencies..."
    (cd "$PI_GIT/pi-telegram" && npm install --silent --no-audit --no-fund >/dev/null 2>&1) || \
      warn "npm install in pi-telegram failed — extension may not load. Retry: cd $PI_GIT/pi-telegram && npm install"
  fi

  # pi-skills — optional, soft fail
  if [ -d "$PI_GIT/pi-skills/.git" ]; then
    ok "pi-skills already cloned"
  else
    info "cloning pi-skills..."
    if git clone --depth 1 https://github.com/badlogic/pi-skills "$PI_GIT/pi-skills" >/dev/null 2>&1; then
      ok "pi-skills cloned"
      if [ -f "$PI_GIT/pi-skills/package.json" ] && [ ! -d "$PI_GIT/pi-skills/node_modules" ]; then
        (cd "$PI_GIT/pi-skills" && npm install --silent --no-audit --no-fund >/dev/null 2>&1) || \
          warn "npm install in pi-skills failed — skills may not load (non-fatal)."
      fi
    else
      warn "Could not clone pi-skills (non-fatal — skills will lazy-load on first run)"
    fi
  fi

  # Sanity: confirm the file patch_telegram needs is on disk before we leave.
  PI_TG="$PI_GIT/pi-telegram/index.ts"
  if [ -f "$PI_TG" ]; then
    ok "pi-telegram source ready at $PI_TG"
    return 0
  else
    warn "pi-telegram cloned but index.ts missing — upstream layout may have changed"
    return 1
  fi
}

# ─── Launch ───────────────────────────────────────────────────
verify_telegram() {
  # Active sanity check: validate the Telegram token + user ID combination
  # *before* we wait for Pi to start. If the token is wrong, we say so now.
  # If the token is right but the user hasn't tapped /start in Telegram yet,
  # we tell them clearly instead of letting messages go silently into a void
  # (the "Olesya's wife" failure mode).
  step "Verifying Telegram setup..."
  TG_VERIFY=$(TG_TOKEN_E="$TG_TOKEN" TG_UID_E="$TG_USER_ID" python3 - <<'PYEOF' 2>/dev/null || echo "ERR"
import json, urllib.request, urllib.error, os
token = os.environ.get("TG_TOKEN_E", "")
uid   = os.environ.get("TG_UID_E", "")
if not token or not uid:
    print("ERR_EMPTY"); raise SystemExit
# 1. getMe — token valid?
try:
    with urllib.request.urlopen(f"https://api.telegram.org/bot{token}/getMe", timeout=8) as r:
        me = json.load(r)
    username = me.get("result", {}).get("username", "")
    if not username:
        print("ERR_TOKEN"); raise SystemExit
except Exception:
    print("ERR_TOKEN"); raise SystemExit
# 2. sendMessage probe — does the user actually have a chat with this bot?
body = json.dumps({"chat_id": int(uid), "text": "🍃 Setup almost done…"}).encode()
req = urllib.request.Request(f"https://api.telegram.org/bot{token}/sendMessage",
                             data=body, headers={"Content-Type":"application/json"})
try:
    with urllib.request.urlopen(req, timeout=8) as r:
        json.load(r)
    print(f"OK:{username}")
except urllib.error.HTTPError as e:
    err = ""
    try:
        err = json.load(e).get("description", "")
    except Exception:
        pass
    if "chat not found" in err.lower() or "blocked" in err.lower() or e.code == 403:
        print(f"ERR_NEED_START:{username}")
    else:
        print(f"ERR_API:{e.code}:{err[:80]}")
except Exception as e:
    print(f"ERR_NET:{e}")
PYEOF
)
  case "$TG_VERIFY" in
    OK:*)
      USERNAME="${TG_VERIFY#OK:}"
      ok "Telegram OK — bot @${USERNAME} can DM you"
      ;;
    ERR_NEED_START:*)
      USERNAME="${TG_VERIFY#ERR_NEED_START:}"
      echo ""
      echo "  ${YELLOW}⚠  Telegram bot is not started yet.${NC}"
      echo "     Open Telegram, find ${PURPLE}@${USERNAME}${NC} and tap ${WHITE}START${NC}."
      echo "     URL: ${PURPLE}https://t.me/${USERNAME}${NC}"
      echo "     After that, the bot will work — no need to re-run this installer."
      echo ""
      ;;
    ERR_TOKEN)
      fail "Telegram bot token is invalid. Re-run the installer and paste the token from @BotFather again."
      ;;
    ERR_EMPTY)
      fail "Telegram token or user ID is empty. Re-run the installer."
      ;;
    *)
      warn "Could not verify Telegram setup ($TG_VERIFY). The bot may still work."
      ;;
  esac
}

launch_bot() {
  step "Launching ${BOT_NAME}..."

  # The plist/service is written with RunAtLoad=false (Codex P1 fix), so
  # there's no autostart racing us. We do the explicit launch here, verify
  # the bridge, and only THEN enable_autostart() registers it for next boot.
  bash "$MAVKA_HOME/launch.sh"
  sleep 3

  if (tmux list-sessions 2>/dev/null | grep -q mavka) || \
     (screen -ls >/dev/null 2>&1 && screen -ls 2>&1 | grep -q mavka); then
    ok "${BOT_NAME} is running!"
    LAUNCH_OK=1
  else
    warn "${BOT_NAME} may need a moment to start. Check: tmux attach -t mavka"
    LAUNCH_OK=0
  fi
}

# ─── Auto-start enable (after verified launch) ────────────────
# Codex P1 fix: only activate the LaunchAgent / systemd unit AFTER we've
# confirmed launch_bot succeeded. If launch failed we leave autostart
# inactive — the user re-runs the installer / fixes their config rather
# than getting a daemon that flaps on every login.
enable_autostart() {
  if [ "${LAUNCH_OK:-0}" != "1" ]; then
    warn "Skipping autostart enable — launch did not verify cleanly."
    return 0
  fi

  step "Enabling auto-start on next login..."
  if [ "$OS" = "mac" ]; then
    PLIST_PATH="$HOME/Library/LaunchAgents/com.mavka.bot.plist"
    if [ -f "$PLIST_PATH" ]; then
      launchctl load "$PLIST_PATH" 2>/dev/null || \
        warn "launchctl load failed — autostart may not work, but the bot is running now."
      ok "LaunchAgent enabled (will auto-start on next login)"
    fi
  elif [ "$OS" = "linux" ]; then
    systemctl --user enable mavka 2>/dev/null || \
      warn "systemctl enable failed — autostart may not work, but the bot is running now."
    ok "Systemd unit enabled (will auto-start on next login)"
  fi
}

# ─── Final ────────────────────────────────────────────────────
show_done() {
  # Clear the screen so the final banner is the only thing the user sees.
  # Avoids the situation where the user scrolls past it into a fresh shell prompt.
  clear 2>/dev/null || true

  # Try to extract the bot username from the token so we can show a deep link
  BOT_LINK=""
  BOT_USERNAME=""
  if [ -f "$HOME/.pi/agent/telegram.json" ] && command -v python3 &>/dev/null; then
    BOT_USERNAME=$(python3 - <<'PYBOT' 2>/dev/null || true
import json, urllib.request, os
try:
    with open(os.path.expanduser("~/.pi/agent/telegram.json")) as f:
        cfg = json.load(f)
    token = cfg.get("botToken", "")
    if not token: raise SystemExit
    req = urllib.request.Request(f"https://api.telegram.org/bot{token}/getMe", method="GET")
    with urllib.request.urlopen(req, timeout=5) as r:
        d = json.load(r)
    username = d.get("result", {}).get("username", "")
    if username:
        print(username)
except Exception:
    pass
PYBOT
)
    [ -n "$BOT_USERNAME" ] && BOT_LINK="https://t.me/$BOT_USERNAME"
  fi

  # Localized "next steps" banner — large, can't miss
  case "$BOT_LANG" in
    ru)
      L_open_tg="ОТКРОЙ TELEGRAM"
      L_step_a="Найди своего бота:"
      L_step_b="Напиши ему: \"Привет\""
      L_step_c="Бот ответит в Telegram. НЕ в этом терминале."
      L_link_label="Прямая ссылка на бота:"
      L_world="🌍 Теперь мир у твоих ног."
      L_terminal_chat="Или общайся с MavKa прямо в терминале — команда:"
      ;;
    uk)
      L_open_tg="ВІДКРИЙ TELEGRAM"
      L_step_a="Знайди свого бота:"
      L_step_b="Напиши йому: \"Привіт\""
      L_step_c="Бот відповість у Telegram. НЕ в цьому терміналі."
      L_link_label="Пряме посилання на бота:"
      L_world="🌍 Тепер світ біля твоїх ніг."
      L_terminal_chat="Або спілкуйся з MavKa прямо в терміналі — команда:"
      ;;
    de)
      L_open_tg="ÖFFNE TELEGRAM"
      L_step_a="Finde deinen Bot:"
      L_step_b="Schreibe ihm: \"Hallo\""
      L_step_c="Der Bot antwortet in Telegram, NICHT in diesem Terminal."
      L_link_label="Direkter Link zum Bot:"
      L_world="🌍 Jetzt liegt dir die Welt zu Füßen."
      L_terminal_chat="Oder chatte mit MavKa direkt im Terminal — Befehl:"
      ;;
    fr)
      L_open_tg="OUVRE TELEGRAM"
      L_step_a="Trouve ton bot :"
      L_step_b="Écris-lui : \"Salut\""
      L_step_c="Le bot répondra dans Telegram, PAS dans ce terminal."
      L_link_label="Lien direct vers le bot :"
      L_world="🌍 Le monde est maintenant à tes pieds."
      L_terminal_chat="Ou parle avec MavKa directement dans le terminal — commande :"
      ;;
    es)
      L_open_tg="ABRE TELEGRAM"
      L_step_a="Encuentra tu bot:"
      L_step_b="Escríbele: \"Hola\""
      L_step_c="El bot responderá en Telegram, NO en este terminal."
      L_link_label="Enlace directo al bot:"
      L_world="🌍 Ahora el mundo está a tus pies."
      L_terminal_chat="O habla con MavKa directamente en la terminal — comando:"
      ;;
    *)
      L_open_tg="OPEN TELEGRAM NOW"
      L_step_a="Find your bot:"
      L_step_b="Write to it: \"Hi\""
      L_step_c="The bot replies in Telegram. NOT in this terminal."
      L_link_label="Direct link to the bot:"
      L_world="🌍 The world is now at your feet."
      L_terminal_chat="Or chat with MavKa right in your terminal — command:"
      ;;
  esac

  echo ""
  # Scenic frame around the MavKa wordmark — sun above, forest below.
  # Olesya is drawing a custom art pass; this is the placeholder.
  echo -e "             ${YELLOW}☀️${NC}    ${PURPLE}🌈${NC}    ${YELLOW}☀️${NC}"
  echo ""
  echo -e "${GREEN}"
  echo '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗ '
  echo '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
  echo '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
  echo '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
  echo '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
  echo '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝'
  echo -e "${NC}"
  echo -e "${GREEN}      🌳   🍃   🌳   🍃   🌳   🍃   🌳   🍃   🌳${NC}"
  echo ""
  echo -e "          ${GREEN}${BOLD}🍃 $L_is_ready${NC}"
  echo -e "          ${GREEN}${L_world}${NC}"
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo ""
  echo -e "          ${BOLD}${WHITE}📱  $L_open_tg${NC}"
  echo ""
  echo -e "  ${WHITE}1.${NC} $L_step_a"
  if [ -n "$BOT_LINK" ]; then
    echo -e "     ${PURPLE}${BOLD}$BOT_LINK${NC}"
  fi
  echo -e "  ${WHITE}2.${NC} $L_step_b"
  echo -e "  ${WHITE}3.${NC} $L_step_c"
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo ""
  echo -e "  ${GREEN}🍃${NC} ${WHITE}$L_terminal_chat${NC}"
  echo -e "       ${GREEN}${BOLD}mavka${NC}"
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo ""
  echo -e "  ${DIM}Logs:    tail -f ~/mavka-bot/mavka.log${NC}"
  echo -e "  ${DIM}Restart: bash ~/mavka-bot/launch.sh${NC}"
  if [ "$OS" = "mac" ]; then
    echo -e "  ${DIM}Stop:    launchctl unload ~/Library/LaunchAgents/com.mavka.bot.plist${NC}"
  else
    echo -e "  ${DIM}Stop:    systemctl --user stop mavka${NC}"
  fi
  echo ""

  # Pause so the user actually sees the final screen and clicks the link
  # before being dropped back to a shell prompt where they might start typing.
  echo ""
  case "$BOT_LANG" in
    ru) PRESS_ENTER="Нажми Enter чтобы открыть чат с MavKa в этом терминале..." ;;
    uk) PRESS_ENTER="Натисни Enter, щоб відкрити чат з MavKa у цьому терміналі..." ;;
    de) PRESS_ENTER="Drücke Enter, um den MavKa-Chat in diesem Terminal zu öffnen..." ;;
    fr) PRESS_ENTER="Appuie sur Entrée pour ouvrir le chat MavKa dans ce terminal..." ;;
    es) PRESS_ENTER="Pulsa Enter para abrir el chat con MavKa en este terminal..." ;;
    *)  PRESS_ENTER="Press Enter to open the MavKa chat in this terminal..." ;;
  esac
  read -p "  $PRESS_ENTER " _ </dev/tty 2>/dev/null || sleep 5

  # On macOS, try to also open the bot in Telegram for the user (parallel
  # surface — chat with the bot in either place).
  if [ "$OS" = "mac" ] && [ -n "$BOT_LINK" ]; then
    open "$BOT_LINK" 2>/dev/null || true
  fi

  # Hand the user over to the live MavKa session in this terminal. The bot
  # is already running in screen/tmux from launch_bot. Attach so the user
  # can talk to it right here and confirm everything works.
  #
  # Detach key sequences differ by backend: tmux is Ctrl+B then D, screen
  # is Ctrl+A then D — pick the message based on which one is actually
  # running. Avoid Ctrl+C, which would SIGINT into the attached bot.
  ATTACH_BACKEND=""
  if command -v tmux >/dev/null 2>&1 && tmux has-session -t mavka 2>/dev/null; then
    ATTACH_BACKEND="tmux"
  elif command -v screen >/dev/null 2>&1 && screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'; then
    ATTACH_BACKEND="screen"
  fi

  if [ -n "$ATTACH_BACKEND" ]; then
    if [ "$ATTACH_BACKEND" = "tmux" ]; then
      DETACH_KEYS="Ctrl+B → D"
    else
      DETACH_KEYS="Ctrl+A → D"
    fi
    echo ""
    case "$BOT_LANG" in
      ru) ATTACH_HINT="${DETACH_KEYS} чтобы выйти из чата (бот останется работать). НЕ Ctrl+C." ;;
      uk) ATTACH_HINT="${DETACH_KEYS} щоб вийти з чату (бот продовжить працювати). НЕ Ctrl+C." ;;
      de) ATTACH_HINT="${DETACH_KEYS} zum Verlassen (der Bot läuft weiter). NICHT Ctrl+C." ;;
      fr) ATTACH_HINT="${DETACH_KEYS} pour quitter (le bot continue de tourner). PAS Ctrl+C." ;;
      es) ATTACH_HINT="${DETACH_KEYS} para salir (el bot sigue corriendo). NO Ctrl+C." ;;
      *)  ATTACH_HINT="${DETACH_KEYS} to detach (bot keeps running). NOT Ctrl+C." ;;
    esac
    echo -e "  ${DIM}${ATTACH_HINT}${NC}"
    echo ""
    sleep 1
    if [ "$ATTACH_BACKEND" = "tmux" ]; then
      tmux -u attach -t mavka 2>/dev/null || true
    else
      # -U forces UTF-8; -x joins an already-attached session; -D -RR
      # forces re-attach if a previous terminal is hung.
      screen -U -x mavka 2>/dev/null || screen -U -D -RR mavka 2>/dev/null || true
    fi
  else
    echo ""
    echo -e "  ${DIM}No tmux/screen available — chat with MavKa via Telegram only.${NC}"
    echo -e "  ${DIM}If you install tmux later, run \`mavka\` to attach.${NC}"
    echo ""
  fi

  # Sanity check: did the session survive? If user accidentally hit Ctrl+C
  # the bot may now be dead and the "keeps running" line below would lie.
  if [ -n "$ATTACH_BACKEND" ]; then
    SESSION_ALIVE="no"
    if [ "$ATTACH_BACKEND" = "tmux" ] && tmux has-session -t mavka 2>/dev/null; then
      SESSION_ALIVE="yes"
    elif [ "$ATTACH_BACKEND" = "screen" ] && screen -ls 2>/dev/null | grep -qE '\.mavka[[:space:]]'; then
      SESSION_ALIVE="yes"
    fi
    if [ "$SESSION_ALIVE" = "no" ]; then
      echo ""
      echo -e "  ${YELLOW}⚠ The session is no longer running (Ctrl+C inside attach kills the bot).${NC}"
      echo -e "  ${DIM}Restart with: ${WHITE}mavka start${NC}${DIM} or ${WHITE}bash ~/mavka-bot/launch.sh${NC}"
      echo ""
      return 0
    fi
  fi

  # After detach: short, warm goodbye so the user knows they're back in shell.
  echo ""
  case "$BOT_LANG" in
    ru) BYE="MavKa продолжает работать в фоне. Запусти 'mavka' чтобы вернуться в чат." ;;
    uk) BYE="MavKa продовжує працювати у фоні. Запусти 'mavka' щоб повернутися в чат." ;;
    de) BYE="MavKa läuft im Hintergrund weiter. Tippe 'mavka' um zurückzukehren." ;;
    fr) BYE="MavKa continue de tourner en arrière-plan. Tape 'mavka' pour revenir." ;;
    es) BYE="MavKa sigue corriendo en segundo plano. Escribe 'mavka' para volver." ;;
    *)  BYE="MavKa keeps running in the background. Type 'mavka' anytime to return." ;;
  esac
  echo -e "  ${GREEN}🍃 ${BYE}${NC}"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────
main() {
  detect_os
  show_header
  collect_info
  install_deps
  create_files
  configure_pi
  verify_telegram
  first_run
  patch_telegram
  setup_autostart
  launch_bot
  enable_autostart
  show_done
}

main "$@"
