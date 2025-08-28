#!/usr/bin/env bash

# Create a 4-pane layout in tmux
tmux_four_panes() {
  tmux split-window -h
  tmux split-window -v
  tmux select-pane -L
  tmux split-window -v
  tmux select-pane -U
}

# Kill all tmux sessions
tmux_kill_all() {
  tmux list-sessions -F '#{session_name}' | xargs -I {} tmux kill-session -t {}
}

# Navigate between tmux sessions
tmux_navigate() {
  if [[ "$1" == "-" ]]; then
    tmux switch-client -l
  else
    tmux switch-client -t "$1"
  fi
}

# Create a new tmux session
tmux_new_session() {
  local session_name="${1:-$(basename "$PWD")}"
  tmux new-session -d -s "$session_name" -c "$PWD"
  tmux switch-client -t "$session_name"
}

# Start a new tmux session if not already in one
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
