#!/usr/bin/env zsh

# Default values for DOTFILES and STOW_FOLDERS if not provided
: "${DOTFILES:=$HOME/.dotfiles}"
: "${STOW_FOLDERS:=bin,nvim,tmux,zsh}"

# Check if GNU Stow is installed
if ! command -v stow &>/dev/null; then
    echo "Error: GNU Stow is not installed. Please install it to continue." >&2
    exit 1
fi

# Navigate to the DOTFILES directory
cd "$DOTFILES" || {
    echo "Error: Failed to navigate to $DOTFILES." >&2
    exit 1
}

# Split STOW_FOLDERS by commas into an array
IFS=',' read -A stow_folders_array <<<"$STOW_FOLDERS"

# Loop over each folder in the array
for folder in "${stow_folders_array[@]}"; do
    echo "Restowing $folder"
    if stow -R "$folder"; then
        echo "Successfully restowed $folder"
    else
        echo "Failed to restow $folder." >&2
    fi
done

# Return to the original directory
cd - || exit 1
