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

  # Determine the default branch dynamically
  local default_branch
  default_branch=$(git -C "$DOTFILES" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@') || default_branch="master"

  # Change to DOTFILES directory
  pushd "$DOTFILES" >/dev/null || {
    echo "Error: Could not access DOTFILES directory."
    return 1
  }

  # Ensure branch is up-to-date with remote
  git pull origin "$default_branch" --rebase

  # Add and commit changes
  git add .
  git commit -m "$commit_message" || echo "No changes to commit in dotfiles."

  # Force push changes
  git push origin "$default_branch" --force --no-verify

  # Return to the original directory
  popd >/dev/null
}
