#!/usr/bin/env bash

commit_dot_files() {
  # Ensure DOTFILES is set
  if [ -z "$DOTFILES" ]; then
    echo "Error: DOTFILES environment variable is not set." >&2
    return 1
  fi

  # Add a timestamp to the commit message
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local commit_message="[AUTOMATED] feat: misc changes to dotfiles - $timestamp"

  # Change to DOTFILES directory
  pushd "$DOTFILES" >/dev/null || {
    echo "Error: Could not access DOTFILES directory."
    return 1
  }

  # Add and commit changes
  git add .
  git commit -m "$commit_message" || echo "No changes to commit in dotfiles."

  # Ensure branch is up-to-date with remote & force push changes
  git_update_current_branch "$DOTFILES"

  # Return to the original directory
  popd >/dev/null || exit
}
