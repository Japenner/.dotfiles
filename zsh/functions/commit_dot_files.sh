commit_dot_files() {
  # Ensure DOTFILES is set
  if [ -z "$DOTFILES" ]; then
    echo "Error: DOTFILES environment variable is not set." >&2
    return 1
  fi

  # Define the commit message
  local commit_message="Automated commit: updates to dotfiles."

  # Determine the default branch dynamically
  local default_branch
  default_branch=$(git -C "$DOTFILES" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@') || default_branch="master"

  # Change to DOTFILES directory
  pushd "$DOTFILES" >/dev/null || {
    echo "Error: Could not access DOTFILES directory."
    return 1
  }

  # Commit changes in the 'personal' subdirectory
  if [ -d "personal" ]; then
    pushd personal >/dev/null
    git add .
    git commit -m "$commit_message" || echo "No changes to commit in 'personal'."
    git push origin "$default_branch"
    popd >/dev/null
  else
    echo "Warning: 'personal' subdirectory not found in $DOTFILES."
  fi

  # Commit changes in the main DOTFILES directory
  git add .
  git commit -m "$commit_message" || echo "No changes to commit in the main dotfiles directory."
  git push origin "$default_branch"

  # Return to the original directory
  popd >/dev/null
}
