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

# Set up directory navigation shortcuts
export DOTFILES="$HOME/.dotfiles"
export REPOS=$HOME/repos
export PERSONAL_REPOS=$REPOS/personal
export WORK_REPOS=$REPOS/$WORK_DIR

# Load custom functions if any exist
for file in $DOTFILES/zsh/functions/*(.N); do
  source "$file"
done

# ===================== OS Specific Setup ===================== #

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[[ "$OSTYPE" == "linux-gnu"* ]] && . "$HOME/.asdf/asdf.sh"
