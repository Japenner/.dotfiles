#!/usr/bin/env zsh

# Set default STOW_FOLDERS if not provided
if [[ -z $STOW_FOLDERS ]]; then
    STOW_FOLDERS="bin,tmux,zsh"
fi

# Set default DOTFILES directory if not provided
if [[ -z $DOTFILES ]]; then
    DOTFILES="$HOME/.dotfiles"
fi

# Export variables to make them available to the refresh.zsh script
export STOW_FOLDERS
export DOTFILES

# Check if the refresh.zsh script exists and is executable
if [[ -x "$DOTFILES/refresh.zsh" ]]; then
    "$DOTFILES/refresh.zsh"
else
    echo "Error: refresh.zsh script not found or not executable at $DOTFILES/refresh.zsh" >&2
    exit 1
fi
