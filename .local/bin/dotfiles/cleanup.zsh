#!/usr/bin/env zsh

# Default values for DOTFILES and STOW_FOLDERS if not provided
: "${DOTFILES:=$HOME/.dotfiles}"
: "${STOW_FOLDERS:=.local,git,nvim,ruby,tmux,zsh,starship}"

# Ensure DOTFILES directory and STOW_FOLDERS are set
if [[ -z "$DOTFILES" || -z "$STOW_FOLDERS" ]]; then
  echo "Error: DOTFILES or STOW_FOLDERS is not set." >&2
  exit 1
fi

# Check if GNU Stow is installed
if ! command -v stow &>/dev/null; then
  echo "Error: GNU Stow is not installed. Please install it to continue." >&2
  exit 1
fi

# Run in a subshell to keep the current directory unchanged
(
  cd "$DOTFILES" || exit 1 # Exit if changing directory fails

  # Split STOW_FOLDERS by commas manually and loop over each folder
  IFS=',' read -A stow_folders_array <<<"$STOW_FOLDERS"

  for folder in "${stow_folders_array[@]}"; do
    echo "Removing $folder"
    stow -D "$folder" || echo "Failed to remove $folder."
  done
)
