#!/usr/bin/env zsh

export ZSH="$HOME/.oh-my-zsh"    # Path to Oh My Zsh installation
export ZSH_TMUX_AUTOSTART="true" # Auto-start tmux with Zsh

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH" ]]; then
  echo "❌ Oh My Zsh is not installed at $ZSH. Skipping plugin load."
  return
fi

# Skip plugin install/update unless in an interactive shell
[[ $- != *i* ]] && return

ZSH_PLUGINS=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zsh-users/zsh-syntax-highlighting
)

for plugin_repo in "${ZSH_PLUGINS[@]}"; do
  plugin_name="${plugin_repo##*/}"
  plugin_path="$ZSH_CUSTOM/plugins/$plugin_name"

  if [[ ! -d "$plugin_path" ]]; then
    echo "🔧 Installing $plugin_name..."
    git clone "https://github.com/$plugin_repo" "$plugin_path"
  elif [[ -d "$plugin_path/.git" ]]; then
    echo "🔄 Updating $plugin_name..."
    git -C "$plugin_path" pull --quiet
  fi
done

# Plugins for Oh My Zsh
plugins=(
  ansible
  asdf
  git
  node
  ruby
  docker
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  history
  fzf
  z
)

export ZSH_THEME="powerlevel10k/powerlevel10k" # Set theme to Powerlevel10k

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"
