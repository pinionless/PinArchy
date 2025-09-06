#!/bin/bash

ansi_art='  ▄███████  ███  ███████▄ [1;34m   ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄[0m
 ███   ███  ███  ███   ███[1;34m  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███[0m
 ███   ███  ███  ███   ███[1;34m  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███[0m
▄███▄▄▄██▀  ███  ███   ███[1;34m ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███[0m
▀███▀▀▀▀    ███  ███   ███[1;34m ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███[0m
 ███        ███  ███   ███[1;34m  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███[0m
 ███        ███  ███   ███[1;34m  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███[0m
 ███        █▀   ███   █▀ [1;34m  ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀[0m'

clear
echo -e "\n$ansi_art\n"

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-pinionless/pinarchy}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

# Use custom branch if instructed, otherwise default to main
OMARCHY_REF="${OMARCHY_REF:-main}"
if [[ $OMARCHY_REF != "main" ]]; then
  echo -e "\eUsing branch: $OMARCHY_REF"
  cd ~/.local/share/omarchy
  git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
  cd -
fi

# Set up installation logging
LOG_FILE="$HOME/omarchy-install-$(date +%Y%m%d-%H%M%S).log"

# Redirect all output to both terminal and log file
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo -e "\nInstallation starting..."
echo "Installation log will be saved to: $LOG_FILE"
source ~/.local/share/omarchy/install.sh
