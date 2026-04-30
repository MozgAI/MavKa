#!/usr/bin/env bash
# MavKa uninstaller — removes all local files and autostart entries.
# Run: bash <(curl -sL https://raw.githubusercontent.com/MozgAI/mavka/main/uninstall.sh)

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
DIM='\033[2;37m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}MavKa uninstaller${NC}"
echo -e "${DIM}This will remove the bot, Pi Agent config, autostart, and all keys.${NC}"
echo ""
echo -e "${DIM}Will NOT revoke API keys on provider websites — you have to do that manually.${NC}"
echo ""
read -p "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

OS="$(uname -s)"

echo ""
echo -e "${DIM}Stopping bot...${NC}"
tmux kill-session -t mavka 2>/dev/null && echo -e "${GREEN}✓${NC} tmux session killed" || echo -e "${DIM}  no tmux session${NC}"
screen -S mavka -X quit 2>/dev/null && echo -e "${GREEN}✓${NC} screen session killed" || true

echo ""
echo -e "${DIM}Disabling autostart...${NC}"
if [[ "$OS" == "Darwin" ]]; then
  PLIST="$HOME/Library/LaunchAgents/com.mavka.bot.plist"
  if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo -e "${GREEN}✓${NC} launchd plist removed"
  else
    echo -e "${DIM}  no launchd entry${NC}"
  fi
else
  if systemctl --user is-enabled mavka.service &>/dev/null; then
    systemctl --user disable --now mavka.service
    rm -f "$HOME/.config/systemd/user/mavka.service"
    systemctl --user daemon-reload
    echo -e "${GREEN}✓${NC} systemd unit removed"
  else
    echo -e "${DIM}  no systemd unit${NC}"
  fi
fi

echo ""
echo -e "${DIM}Removing files...${NC}"

if [[ -d "$HOME/mavka-bot" ]]; then
  rm -rf "$HOME/mavka-bot"
  echo -e "${GREEN}✓${NC} ~/mavka-bot removed"
fi

if [[ -d "$HOME/.pi/agent" ]]; then
  read -p "Remove Pi Agent config (~/.pi/agent)? This affects ALL Pi Agent bots, not just MavKa. [y/N] " pi_confirm
  if [[ "$pi_confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.pi/agent"
    echo -e "${GREEN}✓${NC} ~/.pi/agent removed"
  else
    echo -e "${YELLOW}!${NC} Pi Agent config kept — DeepSeek/Telegram tokens still on disk"
  fi
fi

echo ""
echo -e "${GREEN}Done.${NC}"
echo ""
echo -e "${YELLOW}Don't forget:${NC} revoke API keys on the provider websites."
echo -e "${DIM}  • DeepSeek:    https://platform.deepseek.com/api_keys${NC}"
echo -e "${DIM}  • Groq:        https://console.groq.com/keys${NC}"
echo -e "${DIM}  • Gemini:      https://aistudio.google.com/apikey${NC}"
echo -e "${DIM}  • Tavily:      https://app.tavily.com${NC}"
echo -e "${DIM}  • Telegram:    /revoke command to @BotFather${NC}"
echo ""
