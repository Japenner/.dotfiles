#!/usr/bin/env zsh

# ======================= Initial Setup ======================= #

# Set up directory navigation shortcuts
export DOTFILES="$HOME/.dotfiles"
export REPOS=$HOME/repos
export PERSONAL_REPOS=$REPOS/personal

# Set WORK_DIR if not already defined (you can customize this)
export WORK_DIR=${WORK_DIR:-"work"}  # defaults to "work"
export WORK_REPOS=$REPOS/$WORK_DIR

# Load custom functions if any exist
for file in $DOTFILES/zsh/functions/*(.N); do
  source "$file"
done

# ===================== OS Specific Setup ===================== #

# Load OS-specific configurations
if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES/zsh/.zshrc.macos
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source $DOTFILES/zsh/.zshrc.linux
fi

# ========================= Oh My Zsh ========================= #

# Load all Oh My Zsh related files from the oh-my-zsh directory
for omz_file in $DOTFILES/zsh/oh-my-zsh/*(.N); do
  source "$omz_file"
done

# ===================== Zsh Configuration ===================== #

# Load all .zsh configuration files from the configs directory
for config_file in $DOTFILES/zsh/configs/*(.N); do
  source "$config_file"
done

# ======================= Starship Init ======================= #

# Set Starship config path
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Initialize Starship (this should be in modern-tools.zsh, but adding here as backup)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ================== Load Additional Configs ================== #

# Load FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load other configuration files if available
[ -f ~/.zsh_profile ] && source ~/.zsh_profile
[ -f ~/.aliases ] && source ~/.aliases

# Load all local machine specific .zsh configuration files
for local_config_file in $DOTFILES/zsh/local/*(.N); do
  source "$local_config_file"
done
