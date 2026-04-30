# MavKa 🍃 — Windows uninstaller (PowerShell)
# Removes scheduled task, MavKa home, optionally Pi Agent config.
# Does NOT revoke API keys — do that yourself on each provider.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.ps1 | iex"

$ErrorActionPreference = 'SilentlyContinue'

try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new() } catch {}

$ESC = [char]27
$GREEN  = "$ESC[0;32m"
$YELLOW = "$ESC[0;33m"
$RED    = "$ESC[0;31m"
$DIM    = "$ESC[2m"
$NC     = "$ESC[0m"

Write-Host ""
Write-Host "${YELLOW}MavKa uninstaller (Windows)${NC}"
Write-Host "${DIM}This will remove the scheduled task, MavKa home, and optionally Pi Agent config.${NC}"
Write-Host ""
Write-Host "${DIM}Will NOT revoke API keys on provider websites — you have to do that manually.${NC}"
Write-Host ""

$confirm = Read-Host "Continue? [y/N]"
if ($confirm -notmatch '^[Yy]') {
    Write-Host "Aborted."
    exit 0
}

Write-Host ""
Write-Host "${DIM}Stopping bot...${NC}"
& schtasks /End /TN 'MavKa' 2>&1 | Out-Null
& taskkill /IM pi.exe /F 2>&1 | Out-Null
Write-Host "${GREEN}✓${NC} bot stopped"

Write-Host ""
Write-Host "${DIM}Removing scheduled task...${NC}"
& schtasks /Delete /TN 'MavKa' /F 2>&1 | Out-Null
Write-Host "${GREEN}✓${NC} scheduled task removed"

Write-Host ""
Write-Host "${DIM}Removing files...${NC}"
$mavkaHome = Join-Path $env:USERPROFILE 'mavka-bot'
if (Test-Path $mavkaHome) {
    Remove-Item -Recurse -Force $mavkaHome
    Write-Host "${GREEN}✓${NC} ~\mavka-bot removed"
}

# Remove from PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -like "*$mavkaHome*") {
    $newPath = ($userPath -split ';') | Where-Object { $_ -ne $mavkaHome } | Where-Object { $_ } | Join-String -Separator ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "${GREEN}✓${NC} removed from user PATH"
}

$piHome = Join-Path $env:USERPROFILE '.pi\agent'
if (Test-Path $piHome) {
    Write-Host ""
    $piConfirm = Read-Host "Remove Pi Agent config (~\.pi\agent)? Affects ALL Pi Agent bots. [y/N]"
    if ($piConfirm -match '^[Yy]') {
        Remove-Item -Recurse -Force $piHome
        Write-Host "${GREEN}✓${NC} ~\.pi\agent removed"
    } else {
        Write-Host "${YELLOW}!${NC} Pi Agent config kept — tokens still on disk"
    }
}

Write-Host ""
Write-Host "${GREEN}Done.${NC}"
Write-Host ""
Write-Host "${YELLOW}Don't forget:${NC} revoke API keys on the provider websites."
Write-Host "${DIM}  • DeepSeek:  https://platform.deepseek.com/api_keys${NC}"
Write-Host "${DIM}  • OpenAI:    https://platform.openai.com${NC}"
Write-Host "${DIM}  • Anthropic: https://console.anthropic.com${NC}"
Write-Host "${DIM}  • Moonshot:  https://platform.moonshot.ai${NC}"
Write-Host "${DIM}  • Groq:      https://console.groq.com/keys${NC}"
Write-Host "${DIM}  • Gemini:    https://aistudio.google.com/apikey${NC}"
Write-Host "${DIM}  • Tavily:    https://app.tavily.com${NC}"
Write-Host "${DIM}  • Telegram:  /revoke command to @BotFather${NC}"
Write-Host ""
