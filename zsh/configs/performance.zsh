#!/usr/bin/env zsh

# ============================================
# Performance Optimizations
# ============================================

# Skip in non-interactive shells
[[ $- != *i* ]] && return

# ============= Zsh Options for Performance =============

# Disable some expensive features in large directories
setopt NO_BEEP
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT

# History optimizations
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# ============= Completion Optimizations =============

# Speed up completions
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache

# Limit completion matches for performance
zstyle ':completion:*' max-matches 20

# ============= Lazy Loading Functions =============

# Generic lazy loading function
lazy_load() {
  local command_name="$1"
  local init_command="$2"

  eval "$command_name() {
    unfunction $command_name
    eval '$init_command'
    $command_name \"\$@\"
  }"
}

# ============= Performance Monitoring =============

# Function to profile zsh startup time
zsh_bench() {
  for i in {1..10}; do
    time zsh -i -c exit
  done
}

# Function to find slow loading files
zsh_profile() {
  PS4=$'%D{%M%S%.} %N:%i> '
  exec 3>&2 2>/tmp/zsh_profile.$$
  setopt xtrace prompt_subst
  echo "Profiling enabled. Source your zshrc and then run 'unsetopt xtrace' to stop."
  echo "Results will be in /tmp/zsh_profile.$$"
}
