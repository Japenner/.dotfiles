#!/usr/bin/env zsh

# ============================================
# Modern CLI Tool Replacements
# ============================================

# Only load in interactive shells
[[ $- != *i* ]] && return

# Check if modern tools are installed and create aliases
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias tree='eza --tree --icons'
fi

# Handle bat vs batcat (Ubuntu installs as batcat)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  export BAT_THEME="TwoDark"
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
  alias bat='batcat'
  export BAT_THEME="TwoDark"
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

# Handle fd vs fdfind (Ubuntu installs as fdfind)
if command -v fd >/dev/null 2>&1; then
  alias find='fd'
elif command -v fdfind >/dev/null 2>&1; then
  alias find='fdfind'
  alias fd='fdfind'
fi

# Modern directory navigation with zoxide (replaces 'z' plugin)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ============================================
# Modern Tool Installation Helper
# ============================================

install_modern_tools() {
  echo "🚀 Installing modern CLI tools..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS with Homebrew
    if command -v brew >/dev/null 2>&1; then
      brew install eza bat ripgrep fd zoxide starship delta
      echo "✅ Modern tools installed! Restart your shell to use them."
    else
      echo "❌ Homebrew not found. Please install Homebrew first:"
      echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux - detect package manager
    if command -v apt >/dev/null 2>&1; then
      # Debian/Ubuntu
      echo "📦 Installing via apt..."
      sudo apt update
      sudo apt install -y ripgrep fd-find bat

      # Install from GitHub releases or cargo for tools not in apt
      echo "📦 Installing eza, zoxide, starship via alternative methods..."

      # Install eza via cargo if available, otherwise skip
      if command -v cargo >/dev/null 2>&1; then
        cargo install eza
      else
        echo "⚠️  Skipping eza (requires cargo/rust)"
      fi

      # Install zoxide
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

      # Install starship
      curl -sS https://starship.rs/install.sh | sh

      # Note about bat vs batcat
      echo "ℹ️  Note: On Ubuntu, 'bat' is installed as 'batcat'"
      echo "   Add 'alias bat=batcat' to your aliases if needed"

    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
      # RHEL/CentOS/Fedora
      local pkg_manager="yum"
      command -v dnf >/dev/null 2>&1 && pkg_manager="dnf"

      echo "📦 Installing via $pkg_manager..."
      sudo $pkg_manager install -y ripgrep fd-find bat

      # Install others via curl
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
      curl -sS https://starship.rs/install.sh | sh

      if command -v cargo >/dev/null 2>&1; then
        cargo install eza
      else
        echo "⚠️  Skipping eza (requires cargo/rust)"
      fi

    elif command -v pacman >/dev/null 2>&1; then
      # Arch Linux
      echo "📦 Installing via pacman..."
      sudo pacman -S ripgrep fd bat eza zoxide starship

    else
      echo "❌ Unsupported Linux distribution. Please install manually:"
      echo "   - ripgrep: https://github.com/BurntSushi/ripgrep"
      echo "   - fd: https://github.com/sharkdp/fd"
      echo "   - bat: https://github.com/sharkdp/bat"
      echo "   - eza: https://github.com/eza-community/eza"
      echo "   - zoxide: https://github.com/ajeetdsouza/zoxide"
      echo "   - starship: https://starship.rs/"
      return 1
    fi

    echo "✅ Modern tools installation complete! Restart your shell to use them."
  else
    echo "❌ Unsupported operating system: $OSTYPE"
    return 1
  fi
}

# Alternative installation via package managers
install_via_cargo() {
  if command -v cargo >/dev/null 2>&1; then
    echo "🦀 Installing modern tools via Cargo..."
    cargo install eza bat ripgrep fd-find zoxide starship git-delta
    echo "✅ Cargo installation complete!"
  else
    echo "❌ Cargo not found. Install Rust first: https://rustup.rs/"
  fi
}

# Check what's already installed
check_modern_tools() {
  echo "🔍 Checking modern tool installation status:"

  local tools=("eza" "bat" "rg" "fd" "zoxide" "starship" "delta")
  local missing=()

  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "  ✅ $tool"
    else
      echo "  ❌ $tool"
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "Missing tools: ${missing[*]}"
    echo "Run 'install_modern_tools' to install them."
  else
    echo ""
    echo "🎉 All modern tools are installed!"
  fi
}
