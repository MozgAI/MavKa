# MavKa 🍃 — Windows installer (PowerShell)
# Native PS, no WSL. Mirrors install.sh feature-for-feature.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/MozgAI/MavKa/main/install.ps1 | iex"
#
# Or:
#   git clone https://github.com/MozgAI/mavka.git
#   cd mavka
#   powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = 'Stop'

# Force UTF-8 console so emoji + cyrillic + box-drawing render correctly
try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new() } catch {}
try { $OutputEncoding = [Text.UTF8Encoding]::new() } catch {}

# ─── ANSI colors ────────────────────────────────────────────────
# Win10 1809+ supports ANSI in conhost. Test once and disable if not.
$ANSI = $true
try {
    if ($PSVersionTable.PSVersion.Major -lt 5) { $ANSI = $false }
} catch { $ANSI = $false }

$ESC = [char]27
function _c($code) { if ($ANSI) { "$ESC[$code" + "m" } else { "" } }
$GREEN  = _c '0;32'
$BOLD   = _c '1'
$WHITE  = _c '1;37'
$GREY   = _c '0;37'
$DIM    = _c '2'
$RED    = _c '0;31'
$YELLOW = _c '0;33'
$ORANGE = _c '38;5;208'
$PURPLE = _c '0;35'
$CYAN   = _c '0;36'
$NC     = _c '0'

function info { param($m); Write-Host "  ${DIM}$m${NC}" }
function ok   { param($m); Write-Host "  ${GREEN}✓${NC} ${GREY}$m${NC}" }
function warn { param($m); Write-Host "  ${YELLOW}⚠${NC} $m" }
function fail { param($m); Write-Host "`n${RED}✗ $m${NC}"; exit 1 }

# ─── Step header ────────────────────────────────────────────────
$TOTAL_STEPS = 10
function Step-Header {
    param([int]$idx, [string]$label, [string]$tag)
    $filled = $idx - 1
    $empty  = $TOTAL_STEPS - $filled
    $bar    = ("█" * $filled) + ($DIM + ("·" * $empty) + $NC)
    Write-Host ""
    Write-Host "  ${DIM}─────────────────────────────────────────────────${NC}"
    Write-Host "  ${GREEN}$bar  ${DIM}step $idx/$TOTAL_STEPS${NC}  ·  ${BOLD}${WHITE}$label${NC}  ${DIM}$tag${NC}"
    Write-Host "  ${DIM}─────────────────────────────────────────────────${NC}"
    Write-Host ""
}

# ─── Detect platform ────────────────────────────────────────────
function Detect-OS {
    if ($IsWindows -or $env:OS -match 'Windows') {
        $script:OS = 'windows'
    } else {
        fail "This is the Windows installer. On macOS/Linux, use install.sh instead."
    }
    $script:ARCH = if ([Environment]::Is64BitOperatingSystem) {
        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    } else { 'x86' }
}

# ─── Header ASCII art ───────────────────────────────────────────
function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "${GREEN}"
    Write-Host '   ███╗   ███╗ █████╗ ██╗   ██╗██╗  ██╗ █████╗ '
    Write-Host '   ████╗ ████║██╔══██╗██║   ██║██║ ██╔╝██╔══██╗'
    Write-Host '   ██╔████╔██║███████║██║   ██║█████╔╝ ███████║'
    Write-Host '   ██║╚██╔╝██║██╔══██║╚██╗ ██╔╝██╔═██╗ ██╔══██║'
    Write-Host '   ██║ ╚═╝ ██║██║  ██║ ╚████╔╝ ██║  ██╗██║  ██║'
    Write-Host '   ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝'
    Write-Host "${NC}"
    Write-Host "          ${PURPLE}forest ai 🍃 alive 🍃 listening${NC}"
    Write-Host ""
    Write-Host "   ${DIM}───────────────────────────────────────────────${NC}"
    Write-Host ""
    Write-Host "   ${DIM}Platform: windows ($($script:ARCH))     Home: %USERPROFILE%\mavka-bot${NC}"
    Write-Host ""
}

# ─── i18n ───────────────────────────────────────────────────────
function Set-Lang {
    param([string]$lang)
    $script:BOT_LANG = $lang
    switch ($lang) {
        'uk' {
            $script:L_required        = "обов'язкове поле"
            $script:L_lbl_provider    = "AI-провайдер"
            $script:L_lbl_api_key     = "API ключ"
            $script:L_tag_required    = "обов'язково"
            $script:L_tag_optional    = "необов'язково"
            $script:L_provider_intro  = "Обери мозок для бота. Можна змінити пізніше."
            $script:L_recommended     = "(рекомендується)"
            $script:L_p_deepseek_desc = "~`$2/місяць, найдешевший"
            $script:L_p_chatgpt_desc  = "OpenAI, API ключ"
            $script:L_p_opus_desc     = "Anthropic, API ключ"
            $script:L_p_kimi_desc     = "Moonshot, API ключ. Довгий контекст"
            $script:L_p_groq_desc     = "Llama 3.3 70B, безкоштовний тариф з лімітами"
            $script:L_brain_of        = "мозок MavKa"
            $script:L_signup_at       = "Зареєструйся на"
            $script:L_create_paste    = "створи API ключ і встав сюди"
            $script:L_verifying       = "Перевіряємо ключ..."
            $script:L_key_works       = "API ключ працює!"
            $script:L_ai_activated    = "Помічник активовано!"
            $script:L_ai_guide        = "MavKa проведе тебе через решту налаштування."
            $script:L_ai_natural      = "Пиши природно — задавай питання, якщо щось незрозуміло."
            $script:L_ai_skip         = "Пиши 'пропустити' для необов'язкових кроків."
            $script:L_create_bot      = "Створіть бота:"
            $script:L_botfather_url   = "t.me/BotFather"
            $script:L_botfather_cmd   = "/newbot"
            $script:L_userid_get      = "Отримай свій ID:"
            $script:L_userid_url      = "t.me/userinfobot"
            $script:L_is_ready        = "MavKa готова!"
            $script:L_say_hi          = "Відкрийте Telegram і напишіть привіт!"
        }
        'ru' {
            $script:L_required        = "обязательное поле"
            $script:L_lbl_provider    = "AI-провайдер"
            $script:L_lbl_api_key     = "API ключ"
            $script:L_tag_required    = "обязательно"
            $script:L_tag_optional    = "необязательно"
            $script:L_provider_intro  = "Выбери мозг для бота. Можно сменить позже."
            $script:L_recommended     = "(рекомендуется)"
            $script:L_p_deepseek_desc = "~`$2/месяц, самый дешёвый"
            $script:L_p_chatgpt_desc  = "OpenAI, API ключ"
            $script:L_p_opus_desc     = "Anthropic, API ключ"
            $script:L_p_kimi_desc     = "Moonshot, API ключ. Длинный контекст"
            $script:L_p_groq_desc     = "Llama 3.3 70B, бесплатный тариф с лимитами"
            $script:L_brain_of        = "мозг MavKa"
            $script:L_signup_at       = "Зарегистрируйся на"
            $script:L_create_paste    = "создай API ключ и вставь сюда"
            $script:L_verifying       = "Проверяем ключ..."
            $script:L_key_works       = "API ключ работает!"
            $script:L_ai_activated    = "Помощник активирован!"
            $script:L_ai_guide        = "MavKa проведёт тебя через остальные шаги."
            $script:L_ai_natural      = "Пиши естественно — задавай вопросы, если что-то неясно."
            $script:L_ai_skip         = "Пиши 'пропустить' для необязательных шагов."
            $script:L_create_bot      = "Создайте бота:"
            $script:L_botfather_url   = "t.me/BotFather"
            $script:L_botfather_cmd   = "/newbot"
            $script:L_userid_get      = "Получи свой ID:"
            $script:L_userid_url      = "t.me/userinfobot"
            $script:L_is_ready        = "MavKa готова!"
            $script:L_say_hi          = "Откройте Telegram и напишите привет!"
        }
        default {
            $script:L_required        = "required"
            $script:L_lbl_provider    = "AI Provider"
            $script:L_lbl_api_key     = "API Key"
            $script:L_tag_required    = "required"
            $script:L_tag_optional    = "optional"
            $script:L_provider_intro  = "Pick the brain that powers your bot. You can switch later."
            $script:L_recommended     = "(recommended)"
            $script:L_p_deepseek_desc = "~`$2/month, cheapest"
            $script:L_p_chatgpt_desc  = "OpenAI, API key"
            $script:L_p_opus_desc     = "Anthropic, API key"
            $script:L_p_kimi_desc     = "Moonshot, API key. Long-context"
            $script:L_p_groq_desc     = "Llama 3.3 70B, free tier with daily limits"
            $script:L_brain_of        = "MavKa's brain"
            $script:L_signup_at       = "Sign up at"
            $script:L_create_paste    = "create an API key and paste it here"
            $script:L_verifying       = "Verifying API key..."
            $script:L_key_works       = "API key works!"
            $script:L_ai_activated    = "AI Assistant activated!"
            $script:L_ai_guide        = "MavKa will now guide you through the rest of setup."
            $script:L_ai_natural      = "Type naturally — ask questions if anything is unclear."
            $script:L_ai_skip         = "Type 'skip' to skip optional steps."
            $script:L_create_bot      = "Create a bot:"
            $script:L_botfather_url   = "t.me/BotFather"
            $script:L_botfather_cmd   = "/newbot"
            $script:L_userid_get      = "Get your ID:"
            $script:L_userid_url      = "t.me/userinfobot"
            $script:L_is_ready        = "MavKa is ready!"
            $script:L_say_hi          = "Open Telegram and say hi!"
        }
    }
}

# ─── Provider catalog ───────────────────────────────────────────
function Load-Provider {
    param([string]$name)
    switch ($name) {
        'deepseek' {
            $script:PROVIDER_NAME       = 'deepseek'
            $script:PROVIDER_LABEL      = 'DeepSeek'
            $script:PROVIDER_URL        = 'platform.deepseek.com'
            $script:PROVIDER_VERIFY_URL = 'https://api.deepseek.com/chat/completions'
            $script:PROVIDER_VERIFY_MODEL = 'deepseek-chat'
            $script:PROVIDER_RUN_MODEL  = 'deepseek-v4-flash:off'
            $script:PROVIDER_PI_NAME    = 'deepseek'
            $script:PROVIDER_NOTE       = 'Cheapest. $2 starter credit lasts ~1 year of casual daily use.'
        }
        'openai' {
            $script:PROVIDER_NAME       = 'openai'
            $script:PROVIDER_LABEL      = 'ChatGPT'
            $script:PROVIDER_URL        = 'platform.openai.com'
            $script:PROVIDER_VERIFY_URL = 'https://api.openai.com/v1/chat/completions'
            $script:PROVIDER_VERIFY_MODEL = 'gpt-4o-mini'
            $script:PROVIDER_RUN_MODEL  = 'gpt-4o-mini'
            $script:PROVIDER_PI_NAME    = 'openai'
            $script:PROVIDER_NOTE       = 'GPT-4o-mini. $5 starter credit ≈ 2-3 weeks of daily use.'
        }
        'anthropic' {
            $script:PROVIDER_NAME       = 'anthropic'
            $script:PROVIDER_LABEL      = 'Opus'
            $script:PROVIDER_URL        = 'console.anthropic.com'
            $script:PROVIDER_VERIFY_URL = 'https://api.anthropic.com/v1/messages'
            # Verify with cheap Haiku probe; runtime uses Opus
            $script:PROVIDER_VERIFY_MODEL = 'claude-haiku-4-5'
            $script:PROVIDER_RUN_MODEL  = 'claude-opus-4-7'
            $script:PROVIDER_PI_NAME    = 'anthropic'
            $script:PROVIDER_NOTE       = 'Claude Opus 4.7 — flagship reasoning. Higher cost.'
        }
        'kimi' {
            $script:PROVIDER_NAME       = 'kimi'
            $script:PROVIDER_LABEL      = 'Kimi 2.6'
            $script:PROVIDER_URL        = 'platform.moonshot.ai'
            $script:PROVIDER_VERIFY_URL = 'https://api.moonshot.ai/v1/chat/completions'
            $script:PROVIDER_VERIFY_MODEL = 'kimi-k2.6'
            $script:PROVIDER_RUN_MODEL  = 'kimi-k2.6'
            $script:PROVIDER_PI_NAME    = 'moonshotai'
            $script:PROVIDER_NOTE       = 'Moonshot Kimi-K2.6. 262K context, strong on coding.'
        }
        'groq' {
            $script:PROVIDER_NAME       = 'groq'
            $script:PROVIDER_LABEL      = 'Groq'
            $script:PROVIDER_URL        = 'console.groq.com'
            $script:PROVIDER_VERIFY_URL = 'https://api.groq.com/openai/v1/chat/completions'
            $script:PROVIDER_VERIFY_MODEL = 'llama-3.3-70b-versatile'
            $script:PROVIDER_RUN_MODEL  = 'llama-3.3-70b-versatile'
            $script:PROVIDER_PI_NAME    = 'groq'
            $script:PROVIDER_NOTE       = 'Free tier with daily limits. Fastest inference.'
        }
    }
}

# ─── Refresh PATH after winget installs ─────────────────────────
function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

# ─── Dependency installer ───────────────────────────────────────
function Ensure-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return }
    fail "winget is not installed. MavKa needs Windows 10 1809+ or Windows 11. Install App Installer from the Microsoft Store, then re-run."
}

function Winget-Install {
    param([string]$id, [string]$friendlyName)
    info "Installing $friendlyName..."
    $args = @('install', '-e', '--id', $id, '--silent',
              '--accept-package-agreements', '--accept-source-agreements',
              '--disable-interactivity', '--scope', 'user')
    & winget @args 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        # -1978335189 = APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE (already installed)
        warn "$friendlyName winget exit code $LASTEXITCODE (continuing — may already be installed)"
    } else {
        ok "$friendlyName installed"
    }
}

function Install-Deps {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}  Installing dependencies...${NC}"

    Ensure-Winget

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Winget-Install 'Git.Git' 'Git (includes Git Bash, required by Pi Agent)'
    } else {
        ok "Git already installed"
    }

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Winget-Install 'OpenJS.NodeJS.LTS' 'Node.js LTS'
    } else {
        ok "Node.js already installed ($(node --version))"
    }

    if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
        Winget-Install 'Python.Python.3.12' 'Python 3.12'
    } else {
        ok "Python already installed"
    }

    Refresh-Path

    info "Installing Pi Coding Agent..."
    $piCheck = Get-Command pi -ErrorAction SilentlyContinue
    if (-not $piCheck) {
        & npm install -g '@mariozechner/pi-coding-agent' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            warn "npm install pi-coding-agent failed. Try manually: npm install -g @mariozechner/pi-coding-agent"
        } else {
            ok "Pi Agent installed"
        }
    } else {
        ok "Pi Agent already installed"
    }

    info "Installing edge-tts (voice output)..."
    $pyCmd = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { 'python3' }
    & $pyCmd -m pip install --user --quiet edge-tts 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { ok "edge-tts installed" } else { warn "edge-tts install failed (voice output may not work)" }

    Refresh-Path
}

# ─── Verify API key ─────────────────────────────────────────────
function Verify-ProviderKey {
    param([string]$key)
    $headers = @{ 'Content-Type' = 'application/json' }
    if ($script:PROVIDER_NAME -eq 'anthropic') {
        $headers['x-api-key'] = $key
        $headers['anthropic-version'] = '2023-06-01'
        $body = @{
            model = $script:PROVIDER_VERIFY_MODEL
            max_tokens = 1
            messages = @(@{ role = 'user'; content = 'hi' })
        } | ConvertTo-Json -Depth 5
    } else {
        $headers['Authorization'] = "Bearer $key"
        $body = @{
            model = $script:PROVIDER_VERIFY_MODEL
            messages = @(@{ role = 'user'; content = 'hi' })
            max_tokens = 1
        } | ConvertTo-Json -Depth 5
    }
    try {
        $null = Invoke-RestMethod -Uri $script:PROVIDER_VERIFY_URL -Method Post `
            -Headers $headers -Body $body -TimeoutSec 30
        return $true
    } catch {
        return $false
    }
}

# ─── Collect Info ───────────────────────────────────────────────
function Collect-Info {
    # Step 1: Language
    Step-Header 1 "Language" "required"
    Write-Host "  🇬🇧  ${WHITE}1${NC} ${DIM}English${NC}      🇺🇦  ${WHITE}2${NC} ${DIM}Українська${NC}    🇩🇪  ${WHITE}3${NC} ${DIM}Deutsch${NC}"
    Write-Host "  🇫🇷  ${WHITE}4${NC} ${DIM}Français${NC}     🇪🇸  ${WHITE}5${NC} ${DIM}Español${NC}       🇷🇺  ${WHITE}6${NC} ${DIM}Русский${NC}"
    Write-Host ""
    Write-Host "  ${DIM}Pick / Оберіть / Choisissez (1–6)${NC}"

    $langChoice = Read-Host "  ▸"
    switch ($langChoice) {
        '1' { Set-Lang 'en' }
        '2' { Set-Lang 'uk' }
        '3' { Set-Lang 'de' }
        '4' { Set-Lang 'fr' }
        '5' { Set-Lang 'es' }
        '6' { Set-Lang 'ru' }
        default { Set-Lang 'en' }
    }

    # Step 2: AI Provider
    Step-Header 2 $script:L_lbl_provider $script:L_tag_required
    Write-Host "  ${DIM}$($script:L_provider_intro)${NC}"
    Write-Host ""
    Write-Host "  ${WHITE}1${NC} ${BOLD}DeepSeek${NC}     ${DIM}— $($script:L_p_deepseek_desc)${NC}  ${PURPLE}$($script:L_recommended)${NC}"
    Write-Host "  ${WHITE}2${NC} ${BOLD}ChatGPT${NC}      ${DIM}— $($script:L_p_chatgpt_desc)${NC}"
    Write-Host "  ${WHITE}3${NC} ${BOLD}Opus${NC}         ${DIM}— $($script:L_p_opus_desc)${NC}"
    Write-Host "  ${WHITE}4${NC} ${BOLD}Kimi 2.6${NC}     ${DIM}— $($script:L_p_kimi_desc)${NC}"
    Write-Host "  ${WHITE}5${NC} ${BOLD}Groq${NC}         ${DIM}— $($script:L_p_groq_desc)${NC}"
    Write-Host ""

    $provChoice = Read-Host "  ▸"
    switch ($provChoice) {
        '1' { Load-Provider 'deepseek' }
        '2' { Load-Provider 'openai' }
        '3' { Load-Provider 'anthropic' }
        '4' { Load-Provider 'kimi' }
        '5' { Load-Provider 'groq' }
        default { Load-Provider 'deepseek' }
    }

    # Step 3: API Key
    Step-Header 3 "$($script:PROVIDER_LABEL) $($script:L_lbl_api_key)" $script:L_tag_required
    Write-Host "  ${DIM}$($script:PROVIDER_LABEL) — $($script:L_brain_of) ${NC}🍃${DIM}  —  ${PURPLE}$($script:PROVIDER_URL)${NC}"
    Write-Host "  ${DIM}$($script:PROVIDER_NOTE)${NC}"
    Write-Host ""

    do {
        $script:PROVIDER_KEY = Read-Host "  $($script:PROVIDER_LABEL) $($script:L_lbl_api_key)"
        if ([string]::IsNullOrWhiteSpace($script:PROVIDER_KEY)) {
            Write-Host "  ${RED}⚠ $($script:PROVIDER_LABEL) $($script:L_lbl_api_key) — $($script:L_required)${NC}"
            Write-Host "  ${DIM}  $($script:L_signup_at) $($script:PROVIDER_URL), $($script:L_create_paste).${NC}"
        }
    } while ([string]::IsNullOrWhiteSpace($script:PROVIDER_KEY))

    info $script:L_verifying
    if (Verify-ProviderKey $script:PROVIDER_KEY) {
        ok "$($script:PROVIDER_LABEL) $($script:L_key_works)"
        Write-Host ""
        Write-Host "  ${GREEN}${BOLD}  🍃 $($script:L_ai_activated)${NC}"
        Write-Host "  ${DIM}  $($script:L_ai_guide)${NC}"
        Write-Host "  ${DIM}  $($script:L_ai_natural)${NC}"
        Write-Host "  ${DIM}  $($script:L_ai_skip)${NC}"
        Write-Host ""

        # Run the same Python AI-guided setup as install.sh — fully cross-platform
        $env:MAVKA_AI_KEY        = $script:PROVIDER_KEY
        $env:MAVKA_AI_PROVIDER   = $script:PROVIDER_NAME
        $env:MAVKA_AI_VERIFY_URL = $script:PROVIDER_VERIFY_URL
        $env:MAVKA_AI_MODEL      = $script:PROVIDER_VERIFY_MODEL
        $env:MAVKA_LANG          = $script:BOT_LANG
        $env:MAVKA_STEP_OFFSET   = '3'
        $env:MAVKA_TOTAL_STEPS   = $TOTAL_STEPS
        AI-GuidedSetup
    } else {
        warn "Could not verify API key. Continuing with manual setup..."
        Manual-CollectRemaining
    }
}

# ─── AI-Guided Setup (calls embedded Python) ────────────────────
function AI-GuidedSetup {
    $aiScript = Join-Path $env:TEMP 'mavka-ai-setup.py'
    Set-Content -Path $aiScript -Value (Get-AISetupPython) -Encoding UTF8

    $pyCmd = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { 'python3' }
    & $pyCmd $aiScript
    Remove-Item $aiScript -ErrorAction SilentlyContinue

    $configFile = Join-Path $env:TEMP 'mavka-setup-config.json'
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $script:GROQ_KEY      = $config.groq_key
        $script:GEMINI_KEY    = $config.gemini_key
        $script:TAVILY_KEY    = $config.tavily_key
        $script:TG_TOKEN      = $config.telegram_token
        $script:TG_USER_ID    = $config.telegram_id
        $script:BOT_NAME      = $config.bot_name
        $script:PERSONA       = $config.persona
        Remove-Item $configFile -ErrorAction SilentlyContinue
    }

    if ([string]::IsNullOrWhiteSpace($script:TG_TOKEN)) {
        Write-Host "  ${RED}⚠ Telegram Bot Token is still needed.${NC}"
        do {
            $script:TG_TOKEN = Read-Host "  Telegram Bot Token"
            if ([string]::IsNullOrWhiteSpace($script:TG_TOKEN)) {
                Write-Host "  ${DIM}  $($script:L_create_bot) ${NC}${PURPLE}$($script:L_botfather_url)${NC} ${DIM}→ $($script:L_botfather_cmd)${NC}"
            }
        } while ([string]::IsNullOrWhiteSpace($script:TG_TOKEN))
    }

    if ([string]::IsNullOrWhiteSpace($script:TG_USER_ID)) {
        Write-Host "  ${RED}⚠ Telegram User ID is still needed.${NC}"
        do {
            $script:TG_USER_ID = Read-Host "  Your Telegram User ID"
            if ([string]::IsNullOrWhiteSpace($script:TG_USER_ID)) {
                Write-Host "  ${DIM}  $($script:L_userid_get) ${NC}${PURPLE}$($script:L_userid_url)${NC}"
            }
        } while ([string]::IsNullOrWhiteSpace($script:TG_USER_ID))
    }

    if ([string]::IsNullOrWhiteSpace($script:BOT_NAME)) { $script:BOT_NAME = 'MavKa' }
    if ([string]::IsNullOrWhiteSpace($script:PERSONA)) {
        $script:PERSONA = 'a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. Knowledgeable, concise, always honest.'
    }
}

# ─── Manual fallback when AI verify failed ──────────────────────
function Manual-CollectRemaining {
    Write-Host ""
    Step-Header 6 "Telegram Bot Token" $script:L_tag_required
    Write-Host "  ${DIM}$($script:L_create_bot) ${NC}${PURPLE}$($script:L_botfather_url)${NC} ${DIM}→ $($script:L_botfather_cmd)${NC}"
    do {
        $script:TG_TOKEN = Read-Host "  Telegram Bot Token"
    } while ([string]::IsNullOrWhiteSpace($script:TG_TOKEN))

    Step-Header 7 "Telegram User ID" $script:L_tag_required
    Write-Host "  ${DIM}$($script:L_userid_get) ${NC}${PURPLE}$($script:L_userid_url)${NC}"
    do {
        $script:TG_USER_ID = Read-Host "  Your Telegram User ID"
    } while ([string]::IsNullOrWhiteSpace($script:TG_USER_ID))

    $script:GROQ_KEY = Read-Host "  Groq API Key (voice, optional)"
    $script:GEMINI_KEY = Read-Host "  Gemini API Key (photos, optional)"
    $script:TAVILY_KEY = Read-Host "  Tavily API Key (web search, optional)"

    $script:BOT_NAME = Read-Host "  Bot name [MavKa]"
    if ([string]::IsNullOrWhiteSpace($script:BOT_NAME)) { $script:BOT_NAME = 'MavKa' }
    $script:PERSONA = 'a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. Knowledgeable, concise, always honest.'
}

# ─── Embedded Python AI-setup ───────────────────────────────────
# Identical to the one in install.sh. Reads MAVKA_AI_* env vars.
function Get-AISetupPython {
    return @'
import json, sys, os, re, subprocess, textwrap

AI_KEY = os.environ.get("MAVKA_AI_KEY", os.environ.get("MAVKA_DS_KEY", ""))
AI_PROVIDER = os.environ.get("MAVKA_AI_PROVIDER", "deepseek")
AI_URL = os.environ.get("MAVKA_AI_VERIFY_URL", "https://api.deepseek.com/chat/completions")
AI_MODEL = os.environ.get("MAVKA_AI_MODEL", "deepseek-chat")
BOT_LANG = os.environ.get("MAVKA_LANG", "en")
STEP_OFFSET = int(os.environ.get("MAVKA_STEP_OFFSET", "0"))
TOTAL_STEPS = int(os.environ.get("MAVKA_TOTAL_STEPS", "10"))
CONFIG_FILE = os.path.join(os.environ.get("TEMP", "/tmp"), "mavka-setup-config.json")

LANG_NAMES = {"en":"English","uk":"Ukrainian","ru":"Russian","de":"German","fr":"French","es":"Spanish"}
lang_name = LANG_NAMES.get(BOT_LANG, "English")

GREEN="\033[0;32m"; PURPLE="\033[0;35m"; WHITE="\033[1;37m"; GREY="\033[0;37m"
DIM="\033[2m"; RED="\033[0;31m"; YELLOW="\033[0;33m"; ORANGE="\033[38;5;208m"
CYAN="\033[0;36m"; BOLD="\033[1m"; NC="\033[0m"

STEPS = [
    ("groq_key",       "Groq API Key (voice)",    False),
    ("gemini_key",     "Gemini API Key (photos)", False),
    ("tavily_key",     "Tavily API Key (search)", False),
    ("telegram_token", "Telegram Bot Token",      True),
    ("telegram_id",    "Telegram User ID",        True),
    ("bot_name",       "Bot Name",                False),
    ("persona",        "Personality",             False),
]

config = {"groq_key":"","gemini_key":"","tavily_key":"","telegram_token":"","telegram_id":"",
          "bot_name":"MavKa",
          "persona":"a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. Knowledgeable, concise, always honest."}

LINE_WIDTH = 72

def ai_print(text):
    print()
    paragraphs = [p.strip() for p in text.strip().split("\n") if p.strip()]
    first = True
    for para in paragraphs:
        wrapped = textwrap.wrap(para, width=LINE_WIDTH, break_long_words=False, break_on_hyphens=False) or [""]
        for j, line in enumerate(wrapped):
            if first and j == 0:
                print(f"  🍃 {GREEN}{line}{NC}"); first = False
            else:
                print(f"     {GREEN}{line}{NC}")

def ai_ok(text):   print(); print(f"  {GREEN}✓{NC} {WHITE}{text}{NC}")
def ai_skip(text): print(); print(f"  {ORANGE}◌{NC} {ORANGE}{text}{NC}")
def ai_warn(text): print(); print(f"  {RED}⚠{NC} {GREY}{text}{NC}")

def step_header(step_idx, label, required):
    global_idx = step_idx + STEP_OFFSET + 1
    filled = global_idx - 1
    empty = TOTAL_STEPS - filled
    bar = f"{GREEN}{'█' * filled}{NC}{DIM}{'·' * empty}{NC}"
    tag = f"{DIM}required{NC}" if required else f"{DIM}optional{NC}"
    print()
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print(f"  {bar}  {DIM}step {global_idx}/{TOTAL_STEPS}{NC}  ·  {BOLD}{WHITE}{label}{NC}  {tag}")
    print(f"  {DIM}─────────────────────────────────────────────────{NC}")
    print()

def call_ai(messages, retries=3):
    if AI_PROVIDER == "anthropic":
        return _call_anthropic(messages, retries)
    return _call_openai(messages, retries)

def _call_openai(messages, retries):
    import urllib.request, urllib.error
    payload = json.dumps({"model": AI_MODEL, "messages": messages, "max_tokens": 400, "temperature": 0.5}).encode()
    req = urllib.request.Request(AI_URL, data=payload, method="POST")
    req.add_header("Authorization", f"Bearer {AI_KEY}")
    req.add_header("Content-Type", "application/json")
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
                return data["choices"][0]["message"]["content"]
        except Exception:
            if attempt < retries - 1:
                import time; time.sleep(2)
    return None

def _call_anthropic(messages, retries):
    import urllib.request
    sys_msg = ""; convo = []
    for m in messages:
        if m["role"] == "system": sys_msg = m["content"]
        elif m["role"] in ("user","assistant"): convo.append({"role": m["role"], "content": m["content"]})
    body = {"model": AI_MODEL, "max_tokens": 400, "messages": convo}
    if sys_msg: body["system"] = sys_msg
    payload = json.dumps(body).encode()
    req = urllib.request.Request(AI_URL, data=payload, method="POST")
    req.add_header("x-api-key", AI_KEY)
    req.add_header("anthropic-version", "2023-06-01")
    req.add_header("Content-Type", "application/json")
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
                blocks = data.get("content", [])
                text = "".join(b.get("text","") for b in blocks if b.get("type")=="text")
                return text or None
        except Exception:
            if attempt < retries - 1:
                import time; time.sleep(2)
    return None

def validate_input(field, value):
    v = value.strip()
    if not v: return None
    if   field == "groq_key":      m = re.search(r'(gsk_[A-Za-z0-9]{20,})', v); return m.group(1) if m else None
    elif field == "gemini_key":    m = re.search(r'(AI[A-Za-z0-9_-]{30,})', v); return m.group(1) if m else None
    elif field == "tavily_key":    m = re.search(r'(tvly-[A-Za-z0-9_-]{10,})', v); return m.group(1) if m else None
    elif field == "telegram_token":m = re.search(r'(\d{8,}:[A-Za-z0-9_-]{30,})', v); return m.group(1) if m else None
    elif field == "telegram_id":   m = re.fullmatch(r'\s*(\d{5,12})\s*\.?', v); return m.group(1) if m else None
    elif field == "bot_name":      return v if (len(v) <= 30 and "?" not in v and "!" not in v) else None
    elif field == "persona":       return v
    return None

SKIP_WORDS = ("skip","no","n","later","next","нет","не","ні","пропусти","потом","позже","пізніше","далее","дальше","-","")
def is_skip(text):
    t = text.strip().lower().rstrip(".!?,;:")
    if t in SKIP_WORDS: return True
    cues = ("skip","потом","позже","пізніше","пропуст","later","далее","дальше","следующ","наступн","не сейчас","не зараз","обойд","обійд","не нужно","не треба")
    return any(cue in t for cue in cues)

CMD_RE = re.compile(r'\[CMD:(skip|stay|none)\]', re.IGNORECASE)
def split_cmd(text):
    if not text: return "", ""
    matches = CMD_RE.findall(text)
    cmd = matches[-1].lower() if matches else ""
    visible = CMD_RE.sub("", text).strip()
    return visible, cmd

SYSTEM_PROMPT = f"""You are MavKa — a setup assistant inside a terminal installer.
LANGUAGE — CRITICAL: Detect the user's last message language and reply in it. Initial greeting in {lang_name}.
STYLE: 1-2 sentences. NO emojis. Professional but warm.
STEPS:
1. groq_key — Groq API key, voice transcription. OPTIONAL. console.groq.com/keys
2. gemini_key — Google Gemini, photo analysis. OPTIONAL. aistudio.google.com/apikey
3. tavily_key — Tavily, web search. OPTIONAL. app.tavily.com/home
4. telegram_token — REQUIRED. @BotFather → /newbot
5. telegram_id — REQUIRED. @userinfobot → /start
6. bot_name — Default: MavKa
7. persona — Offer choices: (1) Smart assistant (2) Nutritionist (3) Chef (4) Tutor (5) Custom
RULES:
- ALWAYS finish reply with [CMD:skip], [CMD:stay], or [CMD:none] on its own line.
- skip: user clearly wants to skip (any wording, any layout, any language)
- stay: user is asking, confused, or hasn't answered
- none: user provided what looks like the value (installer validates)
- Required steps: emit [CMD:stay] unless user repeatedly insists on skipping
- NO emojis ever.
"""

messages = [{"role":"system", "content": SYSTEM_PROMPT}]
step_idx = 0

while step_idx < len(STEPS):
    field, label, required = STEPS[step_idx]
    step_header(step_idx, label, required)
    msg = f"[STEP {step_idx+1}] Ask the user for: {label}."
    msg += " REQUIRED — help them get it." if required else " OPTIONAL — they can skip."
    if step_idx == 0:
        msg = f"Greet warmly! Their AI key is set up. Now: {msg}"
    messages.append({"role":"user","content":msg})
    response = call_ai(messages)
    if not response:
        ai_warn("Connection issue, retrying..."); messages.pop(); continue
    messages.append({"role":"assistant","content":response})
    visible, _ = split_cmd(response)
    ai_print(visible if visible else response)

    while True:
        print(); print()
        try:
            user_input = input(f"  🕊️  {WHITE}")
        except (EOFError, KeyboardInterrupt):
            print(); ai_print("Setup cancelled."); sys.exit(1)

        extracted = validate_input(field, user_input) if field not in ("persona","bot_name") else None
        if extracted:
            config[field] = extracted
            disp = extracted[:8] + "•••" if len(extracted) > 12 else extracted
            ai_ok(f"{label}: {disp}"); step_idx += 1; break

        if is_skip(user_input):
            if required:
                ai_warn(f"{label} is required.")
                messages.append({"role":"user","content":"I want to skip"})
                resp = call_ai(messages)
                if resp:
                    messages.append({"role":"assistant","content":resp})
                    v, _ = split_cmd(resp); ai_print(v if v else resp)
                continue
            else:
                config[field] = ""
                ai_skip(f"{label} — skipped"); step_idx += 1; break

        choice = user_input.strip()
        if field == "persona":
            persona_map = {
                "1":"a smart, proactive, and friendly AI assistant. You help with any questions: research, writing, planning, coding, analysis. Knowledgeable, concise, always honest.",
                "2":"an expert nutritionist and fitness coach. You analyze meals, count calories, create meal plans and workouts. Motivating and science-based.",
                "3":"a professional chef and recipe expert. You suggest recipes, explain techniques clearly, and make cooking fun.",
                "4":"a patient language tutor. You help learn languages through conversation, correct mistakes gently.",
            }
            if choice in persona_map:
                config["persona"] = persona_map[choice]; ai_ok("Personality set!"); step_idx += 1; break

        messages.append({"role":"user","content":user_input})
        resp = call_ai(messages)
        if not resp: ai_warn("Connection issue."); messages.pop(); continue
        messages.append({"role":"assistant","content":resp})
        visible, cmd = split_cmd(resp)
        ai_print(visible if visible else resp)

        if cmd == "skip":
            if required: continue
            config[field] = ""; ai_skip(f"{label} — skipped"); step_idx += 1; break

        if cmd == "none":
            if field == "bot_name" and 1 <= len(choice) <= 30:
                config["bot_name"] = choice; ai_ok(f"Bot name: {choice}"); step_idx += 1; break
            if field == "persona" and len(choice) >= 15:
                config["persona"] = choice; ai_ok("Personality set!"); step_idx += 1; break
            extracted = validate_input(field, user_input)
            if extracted:
                config[field] = extracted
                disp = extracted[:8] + "•••" if len(extracted) > 12 else extracted
                ai_ok(f"{label}: {disp}"); step_idx += 1; break

print()
print(f"  {GREEN}{'█' * TOTAL_STEPS}{NC}  {DIM}{TOTAL_STEPS}/{TOTAL_STEPS}  all steps done{NC}")
print(f"  {DIM}─────────────────────────────────────────────────{NC}")
with open(CONFIG_FILE, "w") as f: json.dump(config, f)
print(); ai_print("Setup complete! Installing your bot now... 🍃"); print()
'@
}

# ─── Configure Pi Agent ─────────────────────────────────────────
function Configure-Pi {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}  Configuring Pi Agent...${NC}"

    $piHome = Join-Path $env:USERPROFILE '.pi\agent'
    New-Item -ItemType Directory -Force -Path $piHome | Out-Null

    # auth.json
    $auth = @{}
    if ($script:PROVIDER_KEY) {
        $auth[$script:PROVIDER_PI_NAME] = @{ type = 'api_key'; key = $script:PROVIDER_KEY }
    }
    if ($script:GROQ_KEY -and $script:PROVIDER_PI_NAME -ne 'groq') {
        $auth['groq'] = @{ type = 'api_key'; key = $script:GROQ_KEY }
    }
    if ($script:GEMINI_KEY) {
        $auth['google'] = @{ type = 'api_key'; key = $script:GEMINI_KEY }
    }
    $auth | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $piHome 'auth.json') -Encoding UTF8

    # telegram.json — schema MUST match install.sh / pi-telegram TelegramConfig:
    # { botToken: string, allowedUserId: number, lastUpdateId: number }
    $tg = @{
        botToken = $script:TG_TOKEN
        allowedUserId = [int64]$script:TG_USER_ID
        lastUpdateId = 0
    }
    $tg | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $piHome 'telegram.json') -Encoding UTF8

    # settings.json — pi schema uses `packages` for git/npm extensions, not `extensions`
    $settingsObj = @{
        packages = @(
            'git:github.com/badlogic/pi-telegram',
            'git:github.com/badlogic/pi-skills'
        )
    }
    $gitBash = "C:\Program Files\Git\bin\bash.exe"
    if (Test-Path $gitBash) {
        $settingsObj.shellPath = $gitBash
    } else {
        warn "Git Bash not found at $gitBash. Pi Agent may need manual shell configuration."
    }
    $settingsObj | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $piHome 'settings.json') -Encoding UTF8

    ok "Pi Agent configured"
}

# ─── Create MavKa home + scripts ────────────────────────────────
function Create-Files {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}  Creating MavKa home...${NC}"

    $script:MAVKA_HOME = Join-Path $env:USERPROFILE 'mavka-bot'
    New-Item -ItemType Directory -Force -Path $script:MAVKA_HOME | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:MAVKA_HOME 'memory') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:MAVKA_HOME 'memory\raw') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:MAVKA_HOME 'memory\summaries') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:MAVKA_HOME 'history') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:MAVKA_HOME 'logs') | Out-Null

    # IDENTITY prompt with full LLM Wiki Protocol (mirrors install.sh)
    $identity = @"
# $($script:BOT_NAME) 🍃

You are $($script:BOT_NAME) — $($script:PERSONA)

You communicate via Telegram. The user is your owner.

## Core Rules
1. ALWAYS HONEST — never fabricate facts. If unknown, say so and search.
2. DO NO HARM TO DATA — never delete files. Never share user data.
3. SPEND NO MONEY — never purchase or subscribe.
4. VERIFY BEFORE STATING — check facts online before asserting.

## Tools available
- Web search (Tavily)
- Voice transcription
- Voice → English translation ("British" mode — see below)
- Photo analysis (Gemini Vision)
- Text-to-speech (tts.cmd)
- File system access on the user's machine
- Memory recall: `recall.cmd "query"` (search wiki + history + summaries)
- Hot-swap API key: `setkey.cmd <provider> <new_key>` (deepseek/openai/anthropic/moonshotai/groq/google/tavily)

## Formatting — Telegram sends with parse_mode=HTML

CRITICAL: replies are sent to Telegram with parse_mode=HTML. Use HTML tags, NOT Markdown.

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

## Tables — when you need columns

Wrap padded ASCII rows inside <pre>...</pre>. ASCII characters only (+, -, |). Pad columns to fixed widths. Total width ≤ 32 chars for iPhone portrait. Keep tables ≤ 5 rows.

For 2-3 columns, prefer a bullet list with <b>bold</b> labels — reads faster on a phone.

## "British" mode — voice → English translation

When the user says "Британец", "позови Британця", "включи британца" or similar — switch into British mode:
1. Create marker: `New-Item "$env:USERPROFILE\mavka-bot\.british_mode" -Force`
2. Reply: "Диктуй, переведу"
3. From now on, run `whisper.cmd <audio> --british` for voice messages instead of normal.
4. Reply with ONLY the translated text inside a <pre>...</pre> block. No prefixes, no flags, no commentary.

When the user says "вимкни Британця" / "хватит" — `Remove-Item "$env:USERPROFILE\mavka-bot\.british_mode"` and confirm in one short sentence.

## Hot-swap API key

If the user says "поменяй ключ на ...", "вот новый ключ для DeepSeek: sk-...", "хочу переподключить openai":
1. Identify the provider name (deepseek / openai / anthropic / moonshotai / groq / google / tavily).
2. Run `setkey.cmd <provider> <new_key>`.
3. The script updates auth.json and restarts MavKa automatically.
4. Confirm: "Ключ обновлён, бот перезапущен."

NEVER tell the user to re-run install.ps1 just to change a key.

## Memory System — LLM Wiki Protocol

You have persistent long-term memory at \`%USERPROFILE%\mavka-bot\memory\\\`. This is your "second brain."

Structure:
- MEMORY.md          ← INDEX, lean (≤200 lines), one line per page
- log.md             ← append-only audit (INGEST/QUERY/LINT)
- user_profile.md    ← FROZEN: who the user is
- feedback_*.md      ← FROZEN: rules of behavior the user gave you
- project_*.md       ← active projects, goals, deadlines
- concept_*.md       ← generalizing pages

Page frontmatter:
``````
---
name: <title>
description: <one-line retrieval hook>
type: user | feedback | project | reference | concept
hall: facts | events | discoveries | preferences | advice
frozen: true (optional)
valid_from: YYYY-MM-DD (optional)
ended: YYYY-MM-DD (optional)
---
``````

ON EVERY TURN — read MEMORY.md (index is in your system prompt). Open relevant pages on demand via your read tool.

ON LEARNING SOMETHING NEW — INGEST:
1. Decide which page it belongs to (or create with proper frontmatter).
2. NEVER overwrite a frozen page — only add cross-links [[other.md]].
3. Update temporal fields if facts have a lifecycle.
4. Append a one-line entry to log.md: \`YYYY-MM-DD HH:MM | INGEST | <what> → <pages>\`
5. New pages get a one-line pointer in MEMORY.md (≤150 chars).

NEVER delete a page without explicit user confirmation. Don't write chat logs into memory — memory is for facts, decisions, preferences.

## Communication style
- Warm but concise
- Match the user's language automatically
- For long answers, format with line breaks
- For voice messages, use tts.cmd to reply with audio
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'IDENTITY.md') -Value $identity -Encoding UTF8

    # Seed memory wiki (mirrors install.sh:982 area)
    $today = Get-Date -Format 'yyyy-MM-dd'
    $now   = Get-Date -Format 'yyyy-MM-dd HH:mm'

    $memIndex = Join-Path $script:MAVKA_HOME 'memory\MEMORY.md'
    if (-not (Test-Path $memIndex)) {
        $memIdxContent = @"
# Memory Index

This is the lean index of $($script:BOT_NAME)'s long-term memory. Each line is one wiki page.
Keep this file under 200 lines. One line per page, ≤150 chars per line.
Format: ``- [Title](file.md) — one-line hook``

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
"@
        Set-Content -Path $memIndex -Value $memIdxContent -Encoding UTF8
    }

    $logPath = Join-Path $script:MAVKA_HOME 'memory\log.md'
    if (-not (Test-Path $logPath)) {
        Set-Content -Path $logPath -Value @"
# Memory Log

Append-only chronology: INGEST / QUERY / LINT.
Format: ``YYYY-MM-DD HH:MM | OP | details``

---

$now | INIT | $($script:BOT_NAME) memory wiki created (LLM Wiki Protocol).
"@ -Encoding UTF8
    }

    $upPath = Join-Path $script:MAVKA_HOME 'memory\user_profile.md'
    if (-not (Test-Path $upPath)) {
        Set-Content -Path $upPath -Value @"
---
name: User profile
description: Core facts about the person I'm talking to
type: user
hall: facts
frozen: true
valid_from: $today
---

# User profile

## Basics
- Name: unknown
- Location: unknown
- Role: unknown
- Languages: unknown

## Family
- (will add as I learn)

## Goals (long-term)
- (will add as I learn)

## Health / preferences
- (will add as I learn)

---

Frozen. To update an existing fact, mark old line with ``(ended: YYYY-MM-DD)`` and add the new fact below.
"@ -Encoding UTF8
    }

    # run.cmd — schtasks invokes this on logon. Builds the system prompt
    # by concatenating IDENTITY.md + MEMORY.md + frozen pages, then exec'ing pi.
    $runCmd = @"
@echo off
setlocal
cd /d "%USERPROFILE%\mavka-bot"
echo %DATE% %TIME%: Starting MavKa... >> mavka.log

where pi >nul 2>&1 || (echo pi command not on PATH >> mavka.log & exit /b 1)

set PROMPT_FILE=%TEMP%\mavka-prompt.md
copy /Y "%USERPROFILE%\mavka-bot\IDENTITY.md" "%PROMPT_FILE%" >nul

echo. >> "%PROMPT_FILE%"
echo ## MEMORY INDEX >> "%PROMPT_FILE%"
echo. >> "%PROMPT_FILE%"
if exist "%USERPROFILE%\mavka-bot\memory\MEMORY.md" type "%USERPROFILE%\mavka-bot\memory\MEMORY.md" >> "%PROMPT_FILE%"

echo. >> "%PROMPT_FILE%"
echo ## FROZEN CORE >> "%PROMPT_FILE%"
echo. >> "%PROMPT_FILE%"
if exist "%USERPROFILE%\mavka-bot\memory\user_profile.md" (
    echo ### user_profile.md >> "%PROMPT_FILE%"
    type "%USERPROFILE%\mavka-bot\memory\user_profile.md" >> "%PROMPT_FILE%"
    echo. >> "%PROMPT_FILE%"
)
for %%F in ("%USERPROFILE%\mavka-bot\memory\feedback_*.md") do (
    if /i not "%%~nxF"=="feedback_template.md" (
        echo ### %%~nxF >> "%PROMPT_FILE%"
        type "%%F" >> "%PROMPT_FILE%"
        echo. >> "%PROMPT_FILE%"
    )
)

pi --provider $($script:PROVIDER_PI_NAME) --model $($script:PROVIDER_RUN_MODEL) --append-system-prompt "%PROMPT_FILE%" >> mavka.log 2>&1
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'run.cmd') -Value $runCmd -Encoding ASCII

    # mavka.cmd — user-facing wrapper (start/stop/logs/attach)
    $mavkaCmd = @"
@echo off
setlocal
set ACTION=%1
if "%ACTION%"=="" set ACTION=help

if /i "%ACTION%"=="start" (
    schtasks /Run /TN "MavKa" >nul 2>&1
    echo MavKa started. Check logs: mavka logs
    goto :eof
)
if /i "%ACTION%"=="stop" (
    schtasks /End /TN "MavKa" >nul 2>&1
    taskkill /IM pi.exe /F >nul 2>&1
    echo MavKa stopped.
    goto :eof
)
if /i "%ACTION%"=="logs" (
    powershell -NoProfile -Command "Get-Content -Path '%USERPROFILE%\mavka-bot\mavka.log' -Tail 50 -Wait"
    goto :eof
)
if /i "%ACTION%"=="status" (
    schtasks /Query /TN "MavKa" /V /FO LIST 2>nul | findstr "Status"
    goto :eof
)
if /i "%ACTION%"=="restart" (
    call "%~f0" stop
    timeout /t 2 /nobreak >nul
    call "%~f0" start
    goto :eof
)
if /i "%ACTION%"=="uninstall" (
    schtasks /Delete /TN "MavKa" /F >nul 2>&1
    echo MavKa uninstalled. Files in %USERPROFILE%\mavka-bot remain — delete manually if desired.
    goto :eof
)
echo MavKa control:
echo   mavka start     — start the bot
echo   mavka stop      — stop the bot
echo   mavka restart   — restart
echo   mavka logs      — tail logs (Ctrl+C to stop)
echo   mavka status    — scheduled task status
echo   mavka uninstall — remove scheduled task
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'mavka.cmd') -Value $mavkaCmd -Encoding ASCII

    # tts.cmd — text-to-speech helper for the agent
    $ttsCmd = @"
@echo off
set TEXT=%~1
set OUTPUT=%~2
if "%OUTPUT%"=="" set OUTPUT=%TEMP%\mavka-voice.ogg
if "%TEXT%"=="" (
    echo Usage: tts.cmd "text" [output]
    exit /b 1
)
edge-tts --voice "en-US-AriaNeural" --text "%TEXT%" --write-media "%OUTPUT%" 2>nul && echo %OUTPUT%
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'tts.cmd') -Value $ttsCmd -Encoding ASCII

    # whisper.cmd — Groq Whisper transcription + British mode (translation to English)
    # Usage:
    #   whisper.cmd <audio>              transcribe in native language
    #   whisper.cmd <audio> --british    translate any language to English
    $whisperCmd = @"
@echo off
setlocal
set AUDIO=%~1
set MODE=%~2
if "%AUDIO%"=="" (
    echo Usage: whisper.cmd ^<audio^> [--british]
    exit /b 1
)
if not exist "%AUDIO%" (
    echo Error: file not found: %AUDIO%
    exit /b 1
)
if "%GROQ_API_KEY%"=="" (
    echo Error: GROQ_API_KEY not set
    exit /b 1
)
if /i "%MODE%"=="--british" (
    curl -s -X POST "https://api.groq.com/openai/v1/audio/translations" ^
      -H "Authorization: Bearer %GROQ_API_KEY%" ^
      -F "file=@%AUDIO%" -F "model=whisper-large-v3" -F "response_format=text"
) else (
    curl -s -X POST "https://api.groq.com/openai/v1/audio/transcriptions" ^
      -H "Authorization: Bearer %GROQ_API_KEY%" ^
      -F "file=@%AUDIO%" -F "model=whisper-large-v3" -F "response_format=text"
)
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'whisper.cmd') -Value $whisperCmd -Encoding ASCII

    # setkey.cmd — hot-swap API key without re-running installer
    $setkeyCmd = @"
@echo off
setlocal
set PROV=%~1
set NEWKEY=%~2
if "%PROV%"=="" goto usage
if "%NEWKEY%"=="" goto usage

set AUTH=%USERPROFILE%\.pi\agent\auth.json
if not exist "%AUTH%" (
    echo Error: %AUTH% not found
    exit /b 1
)

if /i "%PROV%"=="tavily" (
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('TAVILY_API_KEY','%NEWKEY%','User')"
    echo + tavily key updated in user environment
    goto restart
)

powershell -NoProfile -Command ^
  "$j = Get-Content '%AUTH%' -Raw | ConvertFrom-Json -AsHashtable; $j['%PROV%'] = @{type='api_key';key='%NEWKEY%'}; $j | ConvertTo-Json -Depth 5 | Set-Content '%AUTH%' -Encoding UTF8"
echo + %PROV% key updated in auth.json

:restart
echo Restarting MavKa...
schtasks /End /TN "MavKa" >nul 2>&1
taskkill /IM pi.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
schtasks /Run /TN "MavKa" >nul 2>&1
echo + MavKa restarted. New key is live.
exit /b 0

:usage
echo Usage: setkey.cmd ^<provider^> ^<new_key^>
echo Providers: deepseek, openai, anthropic, moonshotai, groq, google, tavily
exit /b 1
"@
    Set-Content -Path (Join-Path $script:MAVKA_HOME 'setkey.cmd') -Value $setkeyCmd -Encoding ASCII

    ok "MavKa home created at $($script:MAVKA_HOME)"
}

# ─── Setup autostart via Task Scheduler ─────────────────────────
function Setup-Autostart {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}  Setting up autostart (Task Scheduler)...${NC}"

    $runCmd = Join-Path $script:MAVKA_HOME 'run.cmd'

    # Delete existing task if any
    & schtasks /Delete /TN 'MavKa' /F 2>&1 | Out-Null

    # Create new at-logon, user-level (no admin)
    & schtasks /Create /TN 'MavKa' /TR "`"$runCmd`"" /SC ONLOGON /RL LIMITED /F 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        ok "Autostart configured (runs on user logon)"
    } else {
        warn "Could not register autostart. Run manually: $runCmd"
    }
}

# ─── First run ──────────────────────────────────────────────────
function First-Run {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}  Starting MavKa...${NC}"
    & schtasks /Run /TN 'MavKa' 2>&1 | Out-Null

    Write-Host ""
    Write-Host "  ${GREEN}🍃 $($script:L_is_ready)${NC}"
    Write-Host "  ${DIM}$($script:L_say_hi)${NC}"
    Write-Host ""
    Write-Host "  ${DIM}Control commands:${NC}"
    Write-Host "  ${DIM}  mavka logs     — tail logs${NC}"
    Write-Host "  ${DIM}  mavka stop     — stop the bot${NC}"
    Write-Host "  ${DIM}  mavka restart  — restart${NC}"
    Write-Host "  ${DIM}  mavka uninstall — remove autostart${NC}"
    Write-Host ""
    Write-Host "  ${DIM}Add to PATH for the 'mavka' command:${NC}"
    Write-Host "  ${DIM}  $script:MAVKA_HOME${NC}"
    Write-Host ""
}

# ─── Add MavKa home to user PATH ────────────────────────────────
function Add-ToPath {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$($script:MAVKA_HOME)*") {
        $newPath = if ($userPath) { "$userPath;$($script:MAVKA_HOME)" } else { $script:MAVKA_HOME }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:Path = "$($env:Path);$($script:MAVKA_HOME)"
        ok "Added $($script:MAVKA_HOME) to user PATH (open a new terminal to use 'mavka' command)"
    }
}

# ─── Main ───────────────────────────────────────────────────────
Detect-OS
Show-Header
Set-Lang 'en'  # initial language until step 1

# Beta warning — Windows installer is fresh and lightly tested
Write-Host "  ${YELLOW}⚠ Windows installer is in BETA.${NC}"
Write-Host "  ${DIM}Please report any issues at github.com/MozgAI/MavKa/issues${NC}"
Write-Host ""

Install-Deps
Collect-Info
Configure-Pi
Create-Files
Setup-Autostart
Add-ToPath
First-Run
