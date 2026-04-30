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
      PROVIDER_NOTE="Cheapest. \$2 starter credit lasts ~1 year of casual daily use."
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
      PROVIDER_NOTE="GPT-4o-mini. \$5 starter credit ≈ 2-3 weeks of daily use."
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
      PROVIDER_NOTE="Claude Opus 4.7 — flagship reasoning. Higher cost."
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
      PROVIDER_NOTE="Moonshot Kimi-K2.6. 262K context, strong on coding."
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
      PROVIDER_NOTE="Free tier with daily limits. Fastest inference."
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
      L_ds_credit="\$2 стартового кредиту вистачає на \~рік повсякденного використання"
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
      L_ds_credit="\$2 стартового кредита хватает примерно на \~год обычного использования"
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
      L_ds_credit="\$2 starter credit lasts \~1 year of casual daily use"
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
        m = re.search(r'(tvly-[A-Za-z0-9]{10,})', v)
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
7. persona — Bot personality. Offer choices: (1) Smart assistant (2) Nutritionist (3) Chef (4) Language tutor (5) Custom description.

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

        # Hard-coded value handlers for persona / bot_name (numeric/short-text answers)
        if field == "persona":
            persona_map = {
                "1": "a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. Knowledgeable, concise, always honest.",
                "2": "an expert nutritionist and fitness coach. You analyze meals, count calories, create meal plans and workouts. Motivating and science-based.",
                "3": "a professional chef and recipe expert. You suggest recipes, explain techniques clearly, and make cooking fun.",
                "4": "a patient language tutor. You help learn languages through conversation, correct mistakes gently, and adapt to the learner's level.",
            }
            if choice in persona_map:
                config["persona"] = persona_map[choice]
                ai_ok("Personality set!")
                step_idx += 1
                break
            if choice == "5":
                # Custom — let AI follow up by asking for description, stay
                pass

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
  echo -e "  ${DIM}$L_create_bot${NC} ${PURPLE}$L_botfather_url${NC} ${DIM}→ $L_botfather_cmd${NC}"
  echo ""

  while true; do
    read -p "  $L_tg_token" TG_TOKEN
    [ -n "$TG_TOKEN" ] && break
    echo -e "  ${RED}⚠ Telegram Bot Token — $L_required${NC}"
    echo -e "  ${DIM}  Create one: t.me/BotFather → /newbot${NC}"
  done

  while true; do
    read -p "  $L_tg_id" TG_USER_ID
    [ -n "$TG_USER_ID" ] && break
    echo -e "  ${RED}⚠ Telegram User ID — $L_required${NC}"
    echo -e "  ${DIM}  Get it: t.me/userinfobot${NC}"
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

  # tmux or screen (Pi Agent needs TTY)
  if command -v tmux &>/dev/null; then
    ok "tmux found"
  elif command -v screen &>/dev/null; then
    ok "screen found"
  else
    if [ "$OS" = "linux" ]; then
      info "Installing tmux..."
      sudo apt-get install -y tmux 2>/dev/null || sudo yum install -y tmux 2>/dev/null || \
      sudo pacman -S --noconfirm tmux 2>/dev/null || true
    elif [ "$OS" = "mac" ]; then
      command -v brew &>/dev/null && brew install tmux --quiet 2>/dev/null || true
    fi
    if command -v tmux &>/dev/null; then
      ok "tmux installed"
    elif command -v screen &>/dev/null; then
      ok "screen found (fallback)"
    else
      warn "Neither tmux nor screen found. Install: sudo apt install tmux"
    fi
  fi

  # Pi Agent
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  if command -v pi &>/dev/null; then
    ok "Pi Agent found"
  else
    info "Installing Pi Agent..."
    npm install -g @mariozechner/pi-coding-agent 2>/dev/null
    ok "Pi Agent installed"
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

## Language
Default language: ${BOT_LANG}
Accept input in any language, respond in ${BOT_LANG} unless asked otherwise.

## Formatting
- Use **bold** for emphasis
- Use emoji sparingly — only where they add meaning
- Keep responses concise and actionable
- No headers (#) in messages — use bold text instead

## Tools Available
- Web search: \`bash ~/mavka-bot/search.sh "query" 5\`
- Voice transcription: \`bash ~/mavka-bot/whisper.sh /path/audio.ogg\`
- Text-to-speech: \`bash ~/mavka-bot/tts.sh "text" /tmp/voice.ogg\`
- Photo analysis: \`bash ~/mavka-bot/vision.sh /path/image.jpg "question"\`
- Memory recall: \`bash ~/mavka-bot/recall.sh "query"\`  (search across the wiki, chat history, and distilled summaries)
- Memory lint: \`bash ~/mavka-bot/lint.sh\`  (audit pages — run when the user asks "проверь память")

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

### Format examples

\`feedback_no_emoji.md\`:
\`\`\`
---
name: No emoji in business contexts
description: User dislikes emoji in formal/business replies
type: feedback
hall: preferences
frozen: true
---
Don't use emoji in business or formal contexts.

**Why:** User mentioned 2026-05-01 — "looks unprofessional in client emails."
**How to apply:** Plain text for anything labeled "client", "business", "formal". Casual chat is fine.
\`\`\`

\`project_yoff.md\`:
\`\`\`
---
name: YOFF — handyman + cleaning Calgary
description: Calgary local services, drain/handyman/cleaning, vivid.yoff.ca + luxe.yoff.ca
type: project
hall: events
valid_from: 2026-04-12
---
Active local services business. Two landings: vivid.yoff.ca (handyman), luxe.yoff.ca (cleaning).

**Goal:** lead generation in Calgary, builder license obtained.

[[user_profile.md]] [[calgary_business.md]]
\`\`\`

## Identity
- **Provider:** ${PROVIDER_LABEL}
- **Framework:** Pi Agent + pi-telegram + LLM Wiki memory
- **You are NOT Claude, NOT GPT, NOT Gemini.** You are ${BOT_NAME}.
IDENTITYEOF

  ok "Identity created"

  # ── start.sh ──
  NODE_PATH="$(which node 2>/dev/null || echo '$HOME/.nvm/versions/node/v22.22.2/bin')"
  NODE_DIR="$(dirname "$NODE_PATH")"
  PI_PATH="$(which pi 2>/dev/null || echo "${NODE_DIR}/pi")"

  cat > "$MAVKA_HOME/start.sh" << STARTEOF
#!/bin/bash
export HOME="$HOME"
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
export VOLTA_HOME="\$HOME/.volta"
export PATH="\$VOLTA_HOME/bin:\$HOME/.nvm/versions/node/\$(ls \$HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin:\$HOME/.local/bin:\$PATH"
export DEEPSEEK_API_KEY="${DEEPSEEK_KEY}"
export GROQ_API_KEY="${GROQ_KEY}"
export GEMINI_API_KEY="${GEMINI_KEY}"
export TAVILY_API_KEY="${TAVILY_KEY}"

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

  # ── launch.sh (tmux/screen wrapper — Pi Agent needs TTY) ──
  cat > "$MAVKA_HOME/launch.sh" << 'LAUNCHEOF'
#!/bin/bash
LOGFILE="$HOME/mavka-bot/mavka.log"
echo "$(date): Starting MavKa..." >> "$LOGFILE"

if command -v tmux &>/dev/null; then
  tmux kill-session -t mavka 2>/dev/null
  sleep 1
  tmux new-session -d -s mavka "bash $HOME/mavka-bot/start.sh"
  echo "$(date): MavKa launched in tmux session" >> "$LOGFILE"
elif command -v screen &>/dev/null; then
  screen -S mavka -X quit 2>/dev/null
  sleep 1
  screen -dmS mavka bash "$HOME/mavka-bot/start.sh"
  echo "$(date): MavKa launched in screen session" >> "$LOGFILE"
else
  echo "$(date): ERROR — neither tmux nor screen found" >> "$LOGFILE"
  echo "Install tmux or screen: sudo apt install tmux"
  exit 1
fi
LAUNCHEOF
  chmod +x "$MAVKA_HOME/launch.sh"
  ok "Launcher created"

  # ── search.sh ──
  cat > "$MAVKA_HOME/search.sh" << 'SEARCHEOF'
#!/bin/bash
QUERY="$1"; MAX="${2:-5}"
TAVILY_KEY="${TAVILY_API_KEY}"
[ -z "$QUERY" ] && { echo "Usage: search.sh \"query\" [max]"; exit 1; }
[ -z "$TAVILY_KEY" ] && { echo "Error: TAVILY_API_KEY not set"; exit 1; }

RESULT=$(curl -s -X POST "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_KEY\",\"query\":\"$QUERY\",\"search_depth\":\"advanced\",\"include_answer\":true,\"max_results\":$MAX}" 2>/dev/null)

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
  cat > "$MAVKA_HOME/whisper.sh" << 'WHISPEREOF'
#!/bin/bash
AUDIO="$1"
[ -z "$AUDIO" ] || [ ! -f "$AUDIO" ] && { echo "Error: audio file not found"; exit 1; }
GROQ_KEY="${GROQ_API_KEY}"
[ -z "$GROQ_KEY" ] && { echo "Error: GROQ_API_KEY not set"; exit 1; }
EXT="${AUDIO##*.}"; TMP="/tmp/mavka_whisper.${EXT}"
cp "$AUDIO" "$TMP"
[[ "$EXT" == "oga" ]] && { mv "$TMP" "/tmp/mavka_whisper.ogg"; TMP="/tmp/mavka_whisper.ogg"; }
curl -s -X POST 'https://api.groq.com/openai/v1/audio/transcriptions' \
  -H "Authorization: Bearer $GROQ_KEY" \
  -F "file=@$TMP" -F 'model=whisper-large-v3' -F 'response_format=text'
WHISPEREOF
  chmod +x "$MAVKA_HOME/whisper.sh"

  # ── tts.sh ──
  cat > "$MAVKA_HOME/tts.sh" << 'TTSEOF'
#!/bin/bash
TEXT="$1"; OUTPUT="${2:-/tmp/mavka-voice.ogg}"
[ -z "$TEXT" ] && { echo "Usage: tts.sh \"text\" [output]"; exit 1; }
edge-tts --voice "en-US-AriaNeural" --text "$TEXT" --write-media "$OUTPUT" 2>/dev/null && echo "$OUTPUT" || \
{ echo "Error: TTS failed"; exit 1; }
TTSEOF
  chmod +x "$MAVKA_HOME/tts.sh"

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

# ─── Configure Pi Agent ───────────────────────────────────────
configure_pi() {
  step "Configuring Pi Agent..."

  # Backup existing config if present
  if [ -f "$HOME/.pi/agent/settings.json" ]; then
    BACKUP_DIR="$HOME/.pi/agent/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.pi/agent/"*.json "$BACKUP_DIR/" 2>/dev/null
    ok "Existing Pi Agent config backed up to $BACKUP_DIR"
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
  ]
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

  ok "Pi Agent configured"

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

# 2. Auto-connect on session_start (if not already patched)
if 'pi.on("session_start"' not in content:
    # Find the session_end handler and add session_start before it
    session_end_pattern = r'pi\.on\("session_end"'
    match = re.search(session_end_pattern, content)
    if match:
        insert_pos = match.start()
        auto_connect = '''pi.on("session_start", async (_event, ctx) => {
\t\tconfig = await readConfig();
\t\tawait mkdir(TEMP_DIR, { recursive: true });
\t\tupdateStatus(ctx);
\t\tif (config.botToken) {
\t\t\tawait startPolling(ctx);
\t\t\tupdateStatus(ctx);
\t\t}
\t});

\t'''
        content = content[:insert_pos] + auto_connect + content[insert_pos:]
        changes += 1
        print("✓ Added auto-connect on session_start")
    else:
        print("⚠ Could not find session_end handler for auto-connect patch")

# 3. Check if markdownToTelegramHtml exists
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
    <true/>
    <key>StandardOutPath</key>
    <string>${HOME}/mavka-bot/mavka.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/mavka-bot/mavka-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${HOME}</string>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${HOME}/.nvm/versions/node/v22.22.2/bin:${HOME}/.local/bin:${HOME}/Library/Python/3.9/bin</string>
    </dict>
</dict>
</plist>
PLISTEOF
    # Unload old version first so re-running the installer doesn't error under set -e
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    launchctl load "$PLIST_PATH" 2>/dev/null || true
    ok "LaunchAgent created (auto-start on login)"

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
Environment=PATH=/usr/local/bin:/usr/bin:/bin:${HOME}/.nvm/versions/node/v22.22.2/bin:${HOME}/.local/bin

[Install]
WantedBy=default.target
SVCEOF
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable mavka 2>/dev/null || true
    ok "Systemd service created (auto-start on login)"
  fi
}

# ─── First Run (fetch extensions) ─────────────────────────────
first_run() {
  PI_TG="$HOME/.pi/agent/git/github.com/badlogic/pi-telegram/index.ts"
  if [ -f "$PI_TG" ]; then
    return 0
  fi

  step "First run — downloading extensions..."
  info "Pi Agent needs to fetch pi-telegram on first launch. This takes ~30 seconds."

  if command -v tmux &>/dev/null; then
    tmux kill-session -t mavka 2>/dev/null
    sleep 1
    tmux new-session -d -s mavka "bash $MAVKA_HOME/start.sh"
  elif command -v screen &>/dev/null; then
    screen -S mavka -X quit 2>/dev/null
    sleep 1
    screen -dmS mavka bash "$MAVKA_HOME/start.sh"
  fi

  for i in $(seq 1 60); do
    if [ -f "$PI_TG" ]; then
      ok "pi-telegram downloaded"
      tmux kill-session -t mavka 2>/dev/null || screen -S mavka -X quit 2>/dev/null
      sleep 2
      return 0
    fi
    sleep 2
  done

  tmux kill-session -t mavka 2>/dev/null || screen -S mavka -X quit 2>/dev/null
  warn "pi-telegram download timed out. Run 'bash ~/mavka-bot/patch.sh' after first manual start."
  return 1
}

# ─── Launch ───────────────────────────────────────────────────
launch_bot() {
  step "Launching ${BOT_NAME}..."

  bash "$MAVKA_HOME/launch.sh"
  sleep 3

  if (tmux list-sessions 2>/dev/null | grep -q mavka) || \
     (screen -ls 2>/dev/null | grep -q mavka); then
    ok "${BOT_NAME} is running!"
  else
    warn "${BOT_NAME} may need a moment to start. Check: tmux attach -t mavka"
  fi
}

# ─── Final ────────────────────────────────────────────────────
show_done() {
  echo ""
  echo -e "${GREEN}"
  echo '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗ '
  echo '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
  echo '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
  echo '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
  echo '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
  echo '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝'
  echo -e "${NC}"
  echo -e "          ${GREEN}🍃 $L_is_ready${NC}"
  echo -e "          ${WHITE}$L_say_hi${NC}"
  echo ""
  echo -e "  ${DIM}──────────────────────────────────────────${NC}"
  echo ""
  echo -e "  ${WHITE}Useful commands:${NC}"
  echo -e "  ${DIM}  View logs:      ${GREY}tail -f ~/mavka-bot/mavka.log${NC}"
  echo -e "  ${DIM}  Attach console: ${GREY}tmux attach -t mavka${NC}"
  echo -e "  ${DIM}  Restart:        ${GREY}bash ~/mavka-bot/launch.sh${NC}"
  echo -e "  ${DIM}  Apply patches:  ${GREY}bash ~/mavka-bot/patch.sh${NC}"
  if [ "$OS" = "mac" ]; then
    echo -e "  ${DIM}  Stop:           ${GREY}launchctl unload ~/Library/LaunchAgents/com.mavka.bot.plist${NC}"
  else
    echo -e "  ${DIM}  Stop:           ${GREY}systemctl --user stop mavka${NC}"
  fi
  echo ""
  echo -e "  ${DIM}Cost: ~\$0.10-0.50/month with DeepSeek V4 Flash${NC}"
  echo -e "  ${DIM}Home: ~/mavka-bot/${NC}"
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
  first_run
  patch_telegram
  setup_autostart
  launch_bot
  show_done
}

main "$@"
