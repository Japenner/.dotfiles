#!/usr/bin/env zsh

# Modern Zsh setup example - much faster than Oh My Zsh

# ============= Plugin Manager (Zinit) =============

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if it doesn't exist
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "${ZINIT_HOME}/zinit.zsh"

# ============= Essential Plugins =============

# Load with turbo mode (after prompt appears)
zinit wait lucid for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# ============= Modern Tools =============

# Starship prompt (faster than powerlevel10k)
eval "$(starship init zsh)"

# Modern directory jumping (replaces 'z' plugin)
eval "$(zoxide init zsh)"

# Better 'ls' replacement
alias ls="exa --icons"
alias ll="exa --long --icons --git"
alias tree="exa --tree --icons"

# Modern 'cat' replacement
alias cat="bat"

# Better grep
alias grep="rg"

# ============= Tool Managers =============

# asdf for version management
source ~/.asdf/asdf.sh

# ============= Core Zsh Settings =============

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Completion
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============= Key Bindings =============

bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
