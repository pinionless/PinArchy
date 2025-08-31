#!/bin/bash

# Personal application installations
# This file is sourced by xtras.sh and allows adding custom apps
# without modifying upstream files, making syncing easier.

# =============================================================================
# FUNCTION DEFINITIONS
# =============================================================================

# VSCode theme extension installation function (Ticket 004)
install_vscode_theme_extensions() {
  local extensions=(
    "Catppuccin.catppuccin-vsc"
    "enkia.tokyo-night" 
    "jdinhlife.gruvbox"
    "mvllow.rose-pine"
    "arcticicestudio.nord-visual-studio-code"
    "qufiwefefwoyn.kanagawa"
    "sainnhe.everforest"
    "cleanthemes.matte-black-theme"
    "sherloach.solarized-osaka"
  )
  
  for extension in "${extensions[@]}"; do
    echo "Installing VSCode extension: $extension"
    code --install-extension "$extension" --force || 
      echo -e "\e[33mFailed to install VSCode extension $extension. Continuing...\e[0m"
  done
  
  echo "VSCode theme extensions installation complete."
}

# =============================================================================
# SECTION 1: INSTALL APPS
# =============================================================================

echo "Installing personal applications..."

if [ -z "$OMARCHY_BARE" ]; then
  # Personal applications for tickets 003, 004, 006, 007, 008
  yay -S --noconfirm --needed \
    visual-studio-code-bin \
    thunderbird \
    firefox \
    nano \
    ghostty \
    krusader \
    zsh \
    oh-my-zsh-git
  
  # AUR packages that might be flaky
  for pkg in plexamp-appimage; do
    yay -S --noconfirm --needed "$pkg" ||
      echo -e "\e[31mFailed to install $pkg. Continuing without!\e[0m"
  done
fi

echo "Personal applications installation complete."

# =============================================================================
# SECTION 2: INSTALL EXTENSIONS
# =============================================================================

echo "Installing application extensions..."

if [ -z "$OMARCHY_BARE" ]; then
  # Install VSCode theme extensions (Ticket 004)
  if command -v code &> /dev/null; then
    echo "Installing VSCode theme extensions..."
    install_vscode_theme_extensions
  fi
fi

echo "Application extensions installation complete."

# =============================================================================
# SECTION 3: GIT REPOSITORIES
# =============================================================================

echo "Installing git repositories..."

if [ -z "$OMARCHY_BARE" ]; then
  # zsh-autocomplete plugin for oh-my-zsh (Ticket 003)
  if [ ! -d "/usr/share/oh-my-zsh/custom/plugins/zsh-autocomplete" ]; then
    echo "Installing zsh-autocomplete plugin..."
    sudo git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git /usr/share/oh-my-zsh/custom/plugins/zsh-autocomplete || 
      echo -e "\e[31mFailed to install zsh-autocomplete plugin. Continuing...\e[0m"
  else
    echo "zsh-autocomplete plugin already installed."
  fi

  # zsh-syntax-highlighting plugin for oh-my-zsh (Ticket 003)
  if [ ! -d "/usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting plugin..."
    sudo git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting || 
      echo -e "\e[31mFailed to install zsh-syntax-highlighting plugin. Continuing...\e[0m"
  else
    echo "zsh-syntax-highlighting plugin already installed."
  fi

  # zsh-autosuggestions plugin for oh-my-zsh (Ticket 003)
  if [ ! -d "/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions plugin..."
    sudo git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions || 
      echo -e "\e[31mFailed to install zsh-autosuggestions plugin. Continuing...\e[0m"
  else
    echo "zsh-autosuggestions plugin already installed."
  fi

  # zsh-shift-select plugin for oh-my-zsh (Ticket 003)
  if [ ! -d "/usr/share/oh-my-zsh/custom/plugins/zsh-shift-select" ]; then
    echo "Installing zsh-shift-select plugin..."
    sudo git clone --depth 1 https://github.com/jirutka/zsh-shift-select.git /usr/share/oh-my-zsh/custom/plugins/zsh-shift-select || 
      echo -e "\e[31mFailed to install zsh-shift-select plugin. Continuing...\e[0m"
  else
    echo "zsh-shift-select plugin already installed."
  fi
fi

echo "Git repositories installation complete."

# =============================================================================
# SECTION 4: INSTALL WEBAPPS
# =============================================================================

echo "Installing personal webapps..."

if [ -z "$OMARCHY_BARE" ]; then
  # Custom productivity webapps (moved from main installation for easier upstream syncing)
  omarchy-webapp-install "Google AI Studio" https://aistudio.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-ai.png
  omarchy-webapp-install "Google Calendar" https://calendar.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-calendar.png
  omarchy-webapp-install "Google Sheets" https://sheets.google.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-sheets.png
  omarchy-webapp-install "Claude" https://claude.ai https://claude.ai/favicon.svg
  
  # Password management
  omarchy-webapp-install "Bitwarden" https://vault.bitwarden.com https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/bitwarden.png
fi

echo "Personal webapps installation complete."

echo "All personal installations complete."

# =============================================================================
# SECTION 5: CLI TOOLS
# =============================================================================

echo "Installing CLI tools..."

if [ -z "$OMARCHY_BARE" ]; then
  # CLI tools installation
  yay -S --noconfirm --needed \
    trash-cli
fi

echo "CLI tools installation complete."

# =============================================================================
# SECTION 6: TUI TOOLS
# =============================================================================

echo "Installing TUI tools..."

if [ -z "$OMARCHY_BARE" ]; then
  # TUI tools installation - add tools here as needed
  # Example: yay -S --noconfirm --needed \
  #   some-tui-tool
  echo "No TUI tools configured yet."
fi

echo "TUI tools installation complete."

# =============================================================================
# SECTION 7: SET DEFAULT SHELL
# =============================================================================

echo "Setting zsh as default shell..."

if [ -z "$OMARCHY_BARE" ]; then
  # Set zsh as default shell (Ticket 003)
  if command -v zsh &> /dev/null; then
    # Change shell for current user
    sudo chsh -s $(which zsh) $USER
    echo "Default shell changed to zsh for user: $USER"
    
    # Change shell for root user
    sudo chsh -s $(which zsh) root
    echo "Default shell changed to zsh for root user"
    
    echo "Please restart your session for changes to take effect."
  else
    echo -e "\e[31mzsh not found. Shell change skipped.\e[0m"
  fi
fi

echo "Shell configuration complete."