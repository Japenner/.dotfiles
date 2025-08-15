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

# Custom tmux functions
tmux_new_session() {
    local session_name="${1:-$(basename "$PWD")}"
    tmux new-session -d -s "$session_name" -c "$PWD"
    tmux switch-client -t "$session_name"
}

tmux_kill_all() {
    tmux list-sessions -F '#{session_name}' | xargs -I {} tmux kill-session -t {}
}

# Function to start tmux if not already in a session
start_tmux_if_needed() {
    if [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]] && [[ -n "$SSH_CONNECTION" || "$FORCE_TMUX" == "true" ]]; then
        # Only auto-start tmux in SSH sessions or when explicitly forced
        # This prevents issues with local terminal emulators
        if tmux has-session 2>/dev/null; then
            exec tmux attach-session
        else
            exec tmux new-session
        fi
    fi
}

# Uncomment the line below if you want tmux to auto-start in all terminals
# start_tmux_if_needed
