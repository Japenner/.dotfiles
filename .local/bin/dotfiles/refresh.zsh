#!/usr/bin/env zsh

# Default values for DOTFILES and STOW_FOLDERS if not provided
: "${DOTFILES:=$HOME/.dotfiles}"
: "${STOW_FOLDERS:=.local,git,nvim,ruby,tmux,zsh,starship,vscode}"

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

# Create flat symlink structure in .local/bin
echo "Creating flat symlinks in .local/bin..."

# Ensure target directory exists
mkdir -p "$HOME/.local/bin"

for dir in "$DOTFILES/.local/bin"/*/; do
    [[ -d "$dir" ]] || continue

    for file in "$dir"*; do
        [[ -f "$file" ]] || continue

        filename=$(basename "$file")
        target="$HOME/.local/bin/$filename"

        # Remove existing symlink if it exists
        [[ -L "$target" ]] && rm "$target"

        # Create new symlink
        if ln -s "$file" "$target"; then
            echo "✓ Created: $filename -> $file"
        else
            echo "✗ Failed to create: $filename"
        fi
    done
done

# Return to the original directory
cd - || exit 1
