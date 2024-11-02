#!/usr/bin/env zsh

# Ensure DOTFILES directory and STOW_FOLDERS are set
if [[ -z "$DOTFILES" || -z "$STOW_FOLDERS" ]]; then
  echo "Error: DOTFILES or STOW_FOLDERS is not set." >&2
  exit 1
fi

# Convert STOW_FOLDERS into an array by splitting on commas
stow_folders_array=("${(@s/,/)STOW_FOLDERS}")

# Run in a subshell to keep the current directory unchanged
(
  cd "$DOTFILES" || exit 1  # Exit if changing directory fails

  # Loop over each folder in the array
  for folder in "${stow_folders_array[@]}"; do
    echo "Removing $folder"
    stow -D "$folder"
  done
)
