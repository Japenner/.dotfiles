#!/usr/bin/env zsh

# Enable Vi-mode navigation in the command line
bindkey -v               # Set Vi mode
bindkey "^F" vi-cmd-mode # Use Ctrl+F to switch to command mode in Vi

# Custom keybindings
bindkey "^A" beginning-of-line                   # Move to the beginning of the line
bindkey "^E" end-of-line                         # Move to the end of the line
bindkey "^K" kill-line                           # Delete from the cursor to the end of the line
bindkey "^R" history-incremental-search-backward # Incremental history search
bindkey "^P" history-search-backward             # History search by prefix
bindkey "^Y" accept-and-hold                     # Paste the most recent cut text
bindkey "^N" insert-last-word                    # Insert the last word from the previous command
bindkey "^Q" push-line-or-edit                   # Edit current command in $EDITOR
bindkey -s "^T" "^[Isudo ^[A"                    # Ctrl+T to insert "sudo" at the beginning of the line

# Enable the `Ctrl+S` and `Ctrl+Q` shortcuts by disabling flow control
stty -ixon
