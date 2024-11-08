#!/usr/bin/env zsh

# Colors configuration
autoload -U colors # Load color constants
colors             # Enable color support

# Enable colored output for 'ls' and other commands on FreeBSD-based systems
export CLICOLOR=1

# Default editor settings
export VISUAL=nvim           # Set Neovim as the default visual editor
export EDITOR=$VISUAL        # Set EDITOR to match VISUAL for consistency
export BUNDLER_EDITOR="code" # Set Bundler editor to VS Code
export CODE_EDITOR="code"    # Set VS Code as an external editor

# Suggestion: Customize `LS_COLORS` for better color visibility on `ls`
export LS_COLORS="di=34;1:ln=35;1:so=32;1:pi=33;1:ex=31;1"
