#!/usr/bin/env zsh

# Set defaults
: "${STOW_FOLDERS:=.local,git,nvim,ruby,tmux,zsh,starship,vscode}"
: "${DOTFILES:=$HOME/.dotfiles}"
: "${INSTALL_TOOLS:=ask}"

export STOW_FOLDERS DOTFILES

echo "🚀 Setting up dotfiles..."

# Handle tools if requested
# if [[ "$INSTALL_TOOLS" != "no" ]]; then
#     # Source the modern-tools config to get the functions
#     source "$DOTFILES/zsh/configs/modern-tools.zsh"

#     if [[ "$INSTALL_TOOLS" == "ask" ]]; then
#         check_modern_tools
#         echo ""
#         read "response?Install missing tools? (y/N): "
#         [[ "$response" =~ ^[Yy]$ ]] && install_modern_tools
#     else
#         install_modern_tools
#     fi
# fi

# Stow dotfiles
source "$DOTFILES/.local/bin/dotfiles/refresh.zsh"

echo "✅ Dotfiles setup complete!"
