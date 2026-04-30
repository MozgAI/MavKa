#!/bin/bash
# MavKa 🍃 — Your personal AI assistant in Telegram
# One script. 5 minutes. Less than $1/month.
#
# Usage: bash install.sh
# Or:    curl -sL https://mavka.app/install.sh | bash
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
  echo '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗'
  echo '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
  echo '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
  echo '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
  echo '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
  echo '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝ ╚═╝  ╚═╝╚═╝  ╚═╝'
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
      L_optional="(необов'язково — пропустіть для відключення)"; L_required="обов'язкове поле"
      L_create_bot="Створіть бота: t.me/BotFather → /newbot"
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
      L_optional="(необязательно — пропустите для отключения)"; L_required="обязательное поле"
      L_create_bot="Создайте бота: t.me/BotFather → /newbot"
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
      L_optional="(optional — skip to disable)"; L_required="required"
      L_create_bot="Create a bot: t.me/BotFather → /newbot"
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
  # Language FIRST
  echo -e "${GREEN}${BOLD}  $L_step1${NC}"
  echo ""
  echo -e "  ${DIM}$L_pick_lang${NC}"
  echo -e "  ${DIM}  1) 🇬🇧 English${NC}"
  echo -e "  ${DIM}  2) 🇺🇦 Українська${NC}"
  echo -e "  ${DIM}  3) 🇷🇺 Русский${NC}"
  echo -e "  ${DIM}  4) 🇩🇪 Deutsch${NC}"
  echo -e "  ${DIM}  5) 🇫🇷 Français${NC}"
  echo -e "  ${DIM}  6) 🇪🇸 Español${NC}"
  echo ""

  read -p "  Choice [1]: " LANG_CHOICE
  case "${LANG_CHOICE:-1}" in
    1) BOT_LANG="en" ;;
    2) BOT_LANG="uk" ;;
    3) BOT_LANG="ru" ;;
    4) BOT_LANG="de" ;;
    5) BOT_LANG="fr" ;;
    6) BOT_LANG="es" ;;
    *) BOT_LANG="en" ;;
  esac

  set_lang "$BOT_LANG"

  echo ""
  echo -e "${GREEN}${BOLD}  $L_step2${NC}"
  echo -e "  ${DIM}DeepSeek API Key — the brain of your bot${NC}"
  echo -e "  ${DIM}  Get it free: platform.deepseek.com/api_keys${NC}"
  echo ""

  while true; do
    read -p "  $L_deepseek_key" DEEPSEEK_KEY
    [ -n "$DEEPSEEK_KEY" ] && break
    echo -e "  ${RED}⚠ DeepSeek API Key — $L_required${NC}"
    echo -e "  ${DIM}  Sign up free at platform.deepseek.com, go to API Keys, create one.${NC}"
  done

  # Verify DeepSeek key works
  info "Verifying API key..."
  DS_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $DEEPSEEK_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"hi"}],"max_tokens":1}' \
    "https://api.deepseek.com/chat/completions" 2>/dev/null)

  if [ "$DS_CHECK" = "200" ]; then
    ok "DeepSeek API key works!"
    echo ""
    echo -e "  ${GREEN}${BOLD}  🍃 AI Assistant activated!${NC}"
    echo -e "  ${DIM}  MavKa will now guide you through the rest of setup.${NC}"
    echo -e "  ${DIM}  Type naturally — ask questions if anything is unclear.${NC}"
    echo -e "  ${DIM}  Type 'skip' to skip optional steps.${NC}"
    echo ""

    # Launch AI-guided setup
    export MAVKA_DS_KEY="$DEEPSEEK_KEY"
    export MAVKA_LANG="$BOT_LANG"
    ai_guided_setup
  else
    warn "Could not verify API key (HTTP $DS_CHECK). Continuing with manual setup..."
    manual_collect_remaining
  fi
}

# ─── AI-Guided Setup ─────────────────────────────────────────
ai_guided_setup() {
  CONFIG_FILE="/tmp/mavka-setup-config.json"
  AI_SCRIPT="/tmp/mavka-ai-setup.py"

  cat > "$AI_SCRIPT" << 'AIEOF'
import json, sys, os, re, subprocess, textwrap

DEEPSEEK_KEY = os.environ.get("MAVKA_DS_KEY", "")
BOT_LANG = os.environ.get("MAVKA_LANG", "en")
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
    print(f"  {GREEN}✓{NC} {WHITE}{text}{NC}")

def ai_skip(text):
    print(f"  {ORANGE}◌{NC} {ORANGE}{text}{NC}")

def ai_warn(text):
    print(f"  {RED}⚠{NC} {GREY}{text}{NC}")

def step_header(step_idx, label, required):
    total = len(STEPS)
    filled = step_idx
    bar = f"{GREEN}{'█' * filled}{DIM}{'·' * (total - filled)}{NC}"
    tag = f"{DIM}required{NC}" if required else f"{DIM}optional{NC}"
    print()
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print(f"  {bar}  {DIM}step {filled+1}/{total}{NC}  ·  {BOLD}{WHITE}{label}{NC}  {tag}")
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print()

def step_done():
    print(f"\n  {DIM}─────────────────────────────────────────────────{NC}")

def call_deepseek(messages, retries=3):
    payload = json.dumps({
        "model": "deepseek-chat",
        "messages": messages,
        "max_tokens": 400,
        "temperature": 0.5
    })
    for attempt in range(retries):
        try:
            result = subprocess.run(
                ["curl", "-s", "-X", "POST", "https://api.deepseek.com/chat/completions",
                 "-H", f"Authorization: Bearer {DEEPSEEK_KEY}",
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
        # Must be a pure number, possibly with whitespace/punctuation around
        m = re.fullmatch(r'\s*(\d{5,12})\s*\.?', v)
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
- The installer (not you) decides when to advance to the next step. You just talk.
- DO NOT say "let's move to the next step" or "переходим к следующему" — when the installer is ready to advance, it will move on automatically and show a new step header. If you announce a transition that doesn't happen, the user will be confused.
- If the user asks a question, expresses confusion, says they can't find the key — answer them helpfully on the CURRENT step. Stay focused on the current step's value.
- If the user says skip / later / "потом" / "позже" / "пропустим" / "не сейчас" or similar — just briefly acknowledge ("Окей, можем без этого" / "ok, we can add this later"). DO NOT describe what's next — the installer will show the next step header itself.
- For REQUIRED steps (telegram_token, telegram_id), if the user wants to skip, gently insist and walk them through getting the value step by step.
- If the user pastes something that doesn't match the expected key format, the installer will reject it. Help them — explain what the correct format looks like, where to find it again.
- If the user just wants to chat or asks general questions, answer briefly, then politely return to the current step's question.
- NO emojis ever.
- NEVER output CONFIG lines — the installer handles extraction.
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
    ai_print(response)

    while True:
        print()
        print()  # extra gap between AI message and user prompt
        try:
            user_input = input(f"  ▫️  {WHITE}")
        except (EOFError, KeyboardInterrupt):
            print()
            ai_print("Setup cancelled. Run 'bash install.sh' to start again.")
            sys.exit(1)

        if is_skip(user_input):
            if required:
                ai_warn(f"{label} is required and cannot be skipped.")
                messages.append({"role": "user", "content": "I want to skip this"})
                resp = call_deepseek(messages)
                if resp:
                    messages.append({"role": "assistant", "content": resp})
                    ai_print(resp)
                continue
            else:
                config[field] = ""
                ai_skip(f"{label} — skipped")
                step_idx += 1
                break

        # Detect if input looks like an answer for current step.
        # If not — treat as conversation, let AI reply, stay on this step.
        choice = user_input.strip()
        is_question = "?" in choice or choice.lower().startswith(("how", "what", "why", "where", "when", "can you", "could you", "как", "что", "почему", "где", "можешь", "ты можешь", "як", "що", "чому", "де", "wie", "was", "warum", "wo", "comment", "qu'est", "pourquoi", "où", "cómo", "qué", "por qué", "dónde"))

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
            elif choice == "5" or (not is_question and len(choice) > 25):
                # Custom description — only if not a question
                config["persona"] = choice if len(choice) > 15 else persona_map["1"]
                ai_ok("Personality set!")
                step_idx += 1
                break
            # Otherwise: question or unclear — let AI respond, stay on step
            messages.append({"role": "user", "content": user_input})
            resp = call_deepseek(messages)
            if resp:
                messages.append({"role": "assistant", "content": resp})
                ai_print(resp)
            continue

        if field == "bot_name":
            # Accept name only if it's clearly an answer (short, no question marks)
            if not is_question and 1 <= len(choice) <= 30 and "!" not in choice:
                config["bot_name"] = choice
                ai_ok(f"Bot name: {choice}")
                step_idx += 1
                break
            # Otherwise: question — let AI respond
            messages.append({"role": "user", "content": user_input})
            resp = call_deepseek(messages)
            if resp:
                messages.append({"role": "assistant", "content": resp})
                ai_print(resp)
            continue

        extracted = validate_input(field, user_input)

        if extracted:
            config[field] = extracted
            display_val = extracted[:8] + "•••" if len(extracted) > 12 else extracted
            ai_ok(f"{label}: {display_val}")
            step_idx += 1
            break
        else:
            # Not a valid key, not a skip → user is asking a question or chatting.
            # Reply on the same step, do NOT advance.
            messages.append({"role": "user", "content": user_input})
            resp = call_deepseek(messages)
            if resp:
                messages.append({"role": "assistant", "content": resp})
                ai_print(resp)

total = len(STEPS)
print()
print(f"  {GREEN}{'█' * total}{NC}  {DIM}{total}/{total}  all steps done{NC}")
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
      echo -e "  ${DIM}  Create one: t.me/BotFather → /newbot${NC}"
    done
  fi

  if [ -z "$TG_USER_ID" ]; then
    echo -e "  ${RED}⚠ Telegram User ID is still needed.${NC}"
    while true; do
      read -p "  Your Telegram User ID: " TG_USER_ID
      [ -n "$TG_USER_ID" ] && break
      echo -e "  ${DIM}  Get it: t.me/userinfobot${NC}"
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
  mkdir -p "$HOME/.pi/agent"

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

## Memory System
You have persistent memory in ~/mavka-bot/memory/:
- **MEMORY.md** — index of all memory files
- **rules.md** — user preferences and rules
- **conversations.md** — important facts from chats

**On startup:** Read MEMORY.md and rules.md
**During conversation:** Save important decisions to memory files
**Format:** Date each entry: "$(date +%Y-%m-%d): fact..."

## Identity
- **Model:** DeepSeek V4 Flash (via DeepSeek API)
- **Framework:** Pi Agent + pi-telegram
- **You are NOT Claude, NOT GPT, NOT Gemini.**
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
echo "## MEMORY SNAPSHOT (\$(date +%Y-%m-%d))" >> "\$PROMPT_FILE"
for f in "\$HOME/mavka-bot/memory/"*.md; do
  [ -f "\$f" ] || continue
  echo "### \$(basename \$f)" >> "\$PROMPT_FILE"
  cat "\$f" >> "\$PROMPT_FILE"
  echo "" >> "\$PROMPT_FILE"
done

exec pi --provider deepseek --model deepseek-v4-flash:off \\
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

  # ── Memory ──
  cat > "$MAVKA_HOME/memory/MEMORY.md" << 'MEMEOF'
# MavKa Memory

## Files
- [rules.md](rules.md) — user preferences
- [conversations.md](conversations.md) — important facts from chats
MEMEOF

  cat > "$MAVKA_HOME/memory/rules.md" << 'MEMEOF'
# Rules & Preferences
MEMEOF

  cat > "$MAVKA_HOME/memory/conversations.md" << 'MEMEOF'
# Conversations
MEMEOF

  ok "Memory system initialized"
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

  # Build auth.json with all provided keys
  python3 -c "
import json
auth = {}
dk = '${DEEPSEEK_KEY}'
gk = '${GROQ_KEY}'
gmk = '${GEMINI_KEY}'
if dk: auth['deepseek'] = {'type': 'api_key', 'key': dk}
if gk: auth['groq'] = {'type': 'api_key', 'key': gk}
if gmk: auth['google'] = {'type': 'api_key', 'key': gmk}
with open('$HOME/.pi/agent/auth.json', 'w') as f:
    json.dump(auth, f, indent=2)
"

  ok "Pi Agent configured"
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
    launchctl load "$PLIST_PATH" 2>/dev/null
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
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable mavka 2>/dev/null
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
  echo '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗'
  echo '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
  echo '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
  echo '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
  echo '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
  echo '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝ ╚═╝  ╚═╝╚═╝  ╚═╝'
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
