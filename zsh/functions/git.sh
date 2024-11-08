#!/usr/bin/env bash

# Unalias g if it exists
unalias g 2>/dev/null

# No arguments: `git status`
# With arguments: acts like `git`
g() {
  if [[ $# -gt 0 ]]; then
    git "$@"
  else
    git status
  fi
}
