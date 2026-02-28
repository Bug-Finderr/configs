#!/bin/bash
# Quick setup for a new Mac
# Run from the mac/ directory: ./setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Installing Homebrew ==="
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "=== Installing tools from Brewfile ==="
brew bundle --file=Brewfile

echo "=== Linking configs ==="
LATEST_ZSHRC=$(ls -t backup_zshrc/actual_backups/zshrc_backup_* | head -1)
cp "$LATEST_ZSHRC" ~/.zshrc
cp .zprofile ~/.zprofile
cp .gitconfig ~/.gitconfig
cp ripgrep/.ripgreprc ~/.ripgreprc
mkdir -p ~/.config/bat && cp bat/config ~/.config/bat/config
mkdir -p ~/.config/btop/themes && cp btop/catppuccin_mocha.theme ~/.config/btop/themes/
mkdir -p ~/Library/Application\ Support/eza && cp eza/theme.yml ~/Library/Application\ Support/eza/
mkdir -p ~/Library/Application\ Support/lazygit && cp lazygit/config.yml ~/Library/Application\ Support/lazygit/
mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty && cp ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/
mkdir -p ~/.config/yazi && cp yazi/theme.toml ~/.config/yazi/ && cp yazi/Catppuccin-mocha.tmTheme ~/.config/yazi/

echo "=== Applying macOS defaults ==="
# Key repeat (needs logout)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# No .DS_Store on network/USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Dock
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock mineffect -string "scale"

killall Finder; killall Dock

# Disable Spotlight (free up Cmd+Space for Raycast)
sudo mdutil -a -i off

echo "=== Done! Log out and back in for key repeat changes. ==="
echo "=== Then: System Settings > Keyboard > Shortcuts > Spotlight > uncheck Cmd+Space ==="
