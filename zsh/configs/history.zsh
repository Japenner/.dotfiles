#!/usr/bin/env zsh

# History settings
HISTFILE=~/.zsh_history # Path to store command history
HISTSIZE=10000          # Maximum commands to keep in session history
SAVEHIST=10000          # Maximum commands to save in the history file

# History options
setopt INC_APPEND_HISTORY     # Append commands to history immediately
setopt SHARE_HISTORY          # Share history across sessions
setopt HIST_EXPIRE_DUPS_FIRST # Remove oldest duplicates in history
setopt HIST_FIND_NO_DUPS      # Avoid duplicates when searching history
setopt HIST_IGNORE_ALL_DUPS   # Store only the latest instance of each command
setopt HIST_IGNORE_SPACE      # Ignore commands starting with a space
setopt HIST_REDUCE_BLANKS     # Remove extra blanks from history entries
