#!/bin/bash

# Base directory where all your Git repositories are located
BASE_DIR="$HOME/repos"

# Function to find the primary branch of a git repository
get_primary_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
}

# Iterate over all directories in the base directory
find "$BASE_DIR" -type d -name ".git" | while read -r git_dir; do
  # Go to the Git repository's root directory
  repo_dir="$(dirname "$git_dir")"
  echo "Updating repository: $repo_dir"
  cd "$repo_dir" || continue

  # Check if it's a valid git repository
  if git rev-parse --git-dir >/dev/null 2>&1; then
    # Get the primary branch of the repository
    primary_branch=$(get_primary_branch)

    if [ -z "$primary_branch" ]; then
      echo "Could not determine primary branch for $repo_dir. Skipping..."
      continue
    fi

    # Checkout the primary branch and pull the latest changes
    git checkout "$primary_branch" && git pull
  else
    echo "Not a valid git repository: $repo_dir"
  fi
done
