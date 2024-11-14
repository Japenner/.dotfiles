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

# Wrapper function to stash local changes before running a function and restore them afterward
with_git_stash() {
  local stash_needed=false

  # Check for local changes and stash them if any exist
  if ! git diff --quiet || ! git diff --staged --quiet; then
    git stash -u || { echo "Failed to stash changes."; return 1; }
    stash_needed=true
  fi

  # Execute the specified function
  "$@"
  local result=$?

  # If there was a stash, pop it to restore local changes
  if $stash_needed; then
    git stash pop || { echo "Failed to pop the stash. You may need to resolve conflicts manually."; return 1; }
  fi

  return $result
}
