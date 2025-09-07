#!/bin/bash
set -e  # Exit on error

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
chsh -s $(which zsh)

# Install GitHub CLI
sudo apt update && sudo apt install -y gh

# Install Gemini CLI (confirmed for 2025)
npm install -g @google/gemini-cli

# Sync .zshrc from dotfiles repo
DOTFILES_REPO=${DOTFILES_REPO:-"https://github.com/radlakha/dotfiles.git"}  // Fallback
git clone $DOTFILES_REPO /tmp/dotfiles
cp /tmp/dotfiles/.zshrc ~/.zshrc
rm -rf /tmp/dotfiles
source ~/.zshrc

# Additional Oh My Zsh plugins (if not in .zshrc)
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true
# git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true

echo "Setup complete! Run 'gemini login' for Gemini CLI and 'aws configure sso' for AWS."