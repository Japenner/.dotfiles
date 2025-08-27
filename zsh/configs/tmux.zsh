#!/usr/bin/env zsh

# ============================================
# Tmux Configuration
# ============================================

# Set tmux to use proper terminal for color support
export TERM="xterm-256color"

# Fix for tmux color issues on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    export TERM_PROGRAM_VERSION=""
fi

# Tmux auto-start settings (handled by Oh My Zsh tmux plugin)
# The ZSH_TMUX_AUTOSTART variable is set in oh-my-zsh/plugins.zsh

# Uncomment the line below if you want tmux to auto-start in all terminals
# start_tmux_if_needed
