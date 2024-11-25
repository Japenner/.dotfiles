#!/usr/bin/env zsh

# Enable Powerlevel10k instant prompt. This should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
prompt_file="$cache_dir/p10k-instant-prompt-${USER}.zsh"
if [[ -r "$prompt_file" ]]; then
  source "$prompt_file"
fi

# ======================= Initial Setup ======================= #

# Load custom functions if any exist
for file in ~/.dotfiles/zsh/functions/*(.N); do
  source "$file"
done

# ===================== OS Specific Setup ===================== #

if [[ "$OSTYPE" == "darwin"* ]]; then
  source ~/.dotfiles/zsh/.zshrc.macos
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source ~/.dotfiles/zsh/.zshrc.linux
fi

# ========================= Oh My Zsh ========================= #

export ZSH="$HOME/.oh-my-zsh"           # Path to Oh My Zsh installation
ZSH_THEME="powerlevel10k/powerlevel10k" # Set theme to Powerlevel10k
ZSH_TMUX_AUTOSTART="true"               # Auto-start tmux with Zsh

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

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ===================== Zsh Configuration ===================== #

# Load all .zsh configuration files from the configs directory
for config_file in ~/.dotfiles/zsh/configs/*(.N); do
  source "$config_file"
done

# ================== Load Additional Configs ================== #

# Load FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load other configuration files if available
[ -f ~/.zsh_profile ] && source ~/.zsh_profile
[ -f ~/.aliases ] && source ~/.aliases

# Load all local machine specific .zsh configuration files
for local_config_file in ~/.dotfiles/zsh/local/*(.N); do
  source "$local_config_file"
done

export PYTHON=$(asdf which python3)
export RUBY=$(asdf which ruby)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Docker Desktop
  source "$HOME/.docker/init-zsh.sh" || true
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  . "$HOME/.asdf/asdf.sh"
fi
