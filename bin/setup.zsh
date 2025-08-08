#!/usr/bin/env zsh

# Set default STOW_FOLDERS if not provided
if [[ -z $STOW_FOLDERS ]]; then
    STOW_FOLDERS="bin,git,nvim,ruby,tmux,zsh,starship"
fi

# Set default DOTFILES directory if not provided
if [[ -z $DOTFILES ]]; then
    DOTFILES="$HOME/.dotfiles"
fi

# Export variables to make them available to the refresh.zsh script
export STOW_FOLDERS
export DOTFILES

echo "🚀 Setting up dotfiles..."

# Check if the refresh.zsh script exists
if [[ -f "$DOTFILES/bin/refresh.zsh" ]]; then
    # Source the script
    source "$DOTFILES/bin/refresh.zsh"
else
    echo "Error: refresh.zsh script not found at $DOTFILES/bin/refresh.zsh" >&2
    exit 1
fi

echo "✅ Dotfiles setup complete!"
