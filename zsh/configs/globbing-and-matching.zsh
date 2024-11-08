#!/usr/bin/env zsh

# Enable extended globbing for advanced pattern matching
setopt extendedglob

# Avoid errors on unmatched patterns
unsetopt nomatch

# For case-insensitive matching in filename completion, you can add:
setopt NO_CASE_GLOB # Case-insensitive globbing
