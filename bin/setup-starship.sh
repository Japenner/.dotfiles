#!/usr/bin/env bash

# Starship Configuration Setup
# Creates symlinks for Starship configuration

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

echo "🚀 Setting up Starship configuration..."

# Create .config directory if it doesn't exist
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "📁 Creating $CONFIG_DIR directory..."
    mkdir -p "$CONFIG_DIR"
fi

# Handle existing starship.toml
if [[ -f "$CONFIG_DIR/starship.toml" ]]; then
    if [[ -L "$CONFIG_DIR/starship.toml" ]]; then
        echo "🔗 Existing symlink found, removing..."
        rm "$CONFIG_DIR/starship.toml"
    else
        echo "📋 Backing up existing starship.toml..."
        mv "$CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml.backup"
    fi
fi

# Create symlink
echo "🔗 Creating symlink..."
ln -s "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"

# Verify symlink
if [[ -L "$CONFIG_DIR/starship.toml" ]]; then
    echo "✅ Starship configuration symlinked successfully!"
    echo "   $CONFIG_DIR/starship.toml -> $DOTFILES_DIR/starship/starship.toml"
else
    echo "❌ Failed to create symlink"
    exit 1
fi

echo ""
echo "🎨 To customize your prompt further:"
echo "   Edit: $DOTFILES_DIR/starship/starship.toml"
echo "   Docs: https://starship.rs/config/"
echo ""
echo "💡 Tip: Changes take effect immediately (no restart needed)"
