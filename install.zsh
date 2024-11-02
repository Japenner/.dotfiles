#!/usr/bin/env zsh
# Improved version to forcefully override existing stow folders

# Ensure DOTFILES directory and STOW_FOLDERS are set
if [[ -z "$DOTFILES" || -z "$STOW_FOLDERS" ]]; then
  echo "Error: DOTFILES or STOW_FOLDERS is not set." >&2
  exit 1
fi

# Change to the DOTFILES directory
cd "$DOTFILES" || exit 1

# Loop over each folder, splitting STOW_FOLDERS by commas
for folder in ${(s/,/)STOW_FOLDERS}; do
    echo "Restowing $folder"
    stow -R "$folder" || echo "Failed to restow $folder."
done

# Return to the original directory
cd - || exit 1
