#!/usr/bin/env bash

# Determine the appropriate open command based on OS
open_cmd="open"
command -v open >/dev/null 2>&1 || open_cmd="xdg-open"

# ============================================
# Git Specific Functions
# ============================================

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

# Create a new git worktree and copy untracked files (like .env)
git_create_worktree() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: git_create_worktree <branch-name>"
    return 1
  fi

  local root_dir=$(git rev-parse --show-toplevel)
  local parent_dir=$(dirname "$root_dir")
  local source_path="$root_dir"
  local target_path="$parent_dir/$branch_name"
  local local_branch="jap/$branch_name"

  if [[ -e "$target_path" ]]; then
    echo "❌ Error: Target path already exists at $target_path"
    return 1
  fi

  echo "📁 Creating worktree: $target_path from '$branch_name'"

  git -C "$source_path" fetch origin

  # Determine whether to use local branch or origin fallback
  if git -C "$source_path" show-ref --verify --quiet "refs/heads/$local_branch"; then
    echo "🔄 Using local branch '$local_branch'"
    with_git_stash git -C "$source_path" worktree add "$target_path" "$local_branch" || return 1
  elif git -C "$source_path" ls-remote --exit-code --heads origin "$local_branch" >/dev/null 2>&1; then
    echo "🌱 Creating local branch '$local_branch' from origin/$local_branch"
    with_git_stash git -C "$source_path" worktree add "$target_path" -b "$local_branch" "origin/$local_branch" || return 1
  else
    echo "🌱 Creating local branch '$local_branch'"
    with_git_stash git -C "$source_path" worktree add "$target_path" -b "$local_branch" || return 1
  fi

  echo "📦 Copying untracked files from $source_path → $target_path"

  # Get untracked files, excluding .git directory and other ignored patterns
  local untracked_files
  untracked_files=$(git -C . ls-files --others --exclude storybook-static/ --exclude node_modules --exclude build --exclude .DS_Store --exclude dev-dist --exclude "*/.*/")

  if [[ -n "$untracked_files" ]]; then
    while IFS= read -r file; do
      local source_file="$source_path/$file"
      local target_file="$target_path/$file"
      local target_dir=$(dirname "$target_file")

      # Create target directory structure
      mkdir -p "$target_dir"

      # Copy the file if it exists and is readable
      if [[ -f "$source_file" && -r "$source_file" ]]; then
          cp "$source_file" "$target_file"
          echo "  ✅ Copied: $file"
      fi
    done <<< "$untracked_files"
  else
    echo "  ℹ️  No untracked files to copy"
  fi

  echo "✅ Worktree ready: $target_path"

  cd "$target_path" || {
    echo "❌ Error: Failed to change directory to $target_path"
    return 1
  }
}

# Get the default branch based on the remote's HEAD
git_default_branch() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

# Get the current branch for a given path (default: current directory)
git_current_branch() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" symbolic-ref --short HEAD
}

# Update the current branch by rebasing it on top of the default branch
git_update_current_branch() {
  local file_path=${1:-$(pwd)}
  local default_branch=$(git_default_branch "$file_path")

  git -C "$file_path" fetch origin
  git -C "$file_path" pull origin "$default_branch" --rebase
  git -C "$file_path" push origin "$(git_current_branch "$file_path")" --force --no-verify
}

# Commit all changes in the current branch of the given repository with a WIP message
git_commit_wip() {
  # Capture whether a directory was provided
  local dir_provided=false
  if [ -n "$1" ]; then
    dir_provided=true
  fi

  # Set the file path to the provided argument or use current directory
  local file_path=${1:-$(pwd)}

  # Add a timestamp to the commit message
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local commit_message="[AUTOMATED] WIP - $timestamp"

  # Change to the file_path directory
  pushd "$file_path" >/dev/null || {
    echo "Error: Could not access directory."
    return 1
  }

  # Add and commit changes
  git add .
  git commit -m "$commit_message" || echo "No changes to commit in provided path."

  # Return to the original directory if it was changed
  if [ "$dir_provided" = true ]; then
    popd >/dev/null || exit
  fi
}

# Force commit all changes in the current branch of the given repository
git_force_commit_changes() {
  local file_path=${1:-$(pwd)}

  # Add a timestamp to the commit message
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local commit_message="[AUTOMATED] feat: misc changes - $timestamp"

  # Change to file_path directory
  pushd "$file_path" >/dev/null || {
    echo "Error: Could not access directory."
    return 1
  }

  # Add and commit changes
  git add .
  git commit -m "$commit_message" || echo "No changes to commit in provided path."

  # Ensure branch is up-to-date with remote & force push changes
  git_update_current_branch "$file_path"

  # Return to the original directory
  popd >/dev/null || exit
}

# Prune local branches that are tracking deleted remotes
git_prune_local_branches() {
  git fetch --prune

  branches_to_delete=()
  while IFS= read -r branch; do
    branches_to_delete+=("$branch")
  done < <(git branch -vv | awk '!/^\*/ && /: gone]/{print $1}')

  if [[ ${#branches_to_delete[@]} -eq 0 ]]; then
    echo "No local branches to prune."
    return 0
  fi

  echo "The following branches are tracking deleted remotes:"
  for branch in "${branches_to_delete[@]}"; do
    echo "  - $branch"
  done

  echo -n "Delete these branches? (y/N): "
  read -r confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for branch in "${branches_to_delete[@]}"; do
      echo "Deleting $branch..."
      if ! git branch -d "$branch"; then
        git branch -D "$branch"
      fi
      echo ""
    done
    echo "✅ Branches deleted."
  else
    echo "❌ No branches deleted."
  fi
}

# Validate that we're in a git repository
validate_git_repo() {
  local file_path=${1:-$(pwd)}
  if ! git -C "$file_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not inside a Git repository." >&2
    return 1
  fi
  return 0
}

# ============================================
# Github Specific Functions
# ============================================

# Open the GitHub compare page between the current branch and default branch in the browser
github_compare_current_branch() {
  local file_path=${1:-$(pwd)}
  local current_branch=${2:-$(git_current_branch "$file_path")}
  local project_root=$(github_project_root "$file_path")
  local default_branch=$(git_default_branch "$file_path")

  ${open_cmd} "${project_root}/compare/${default_branch}...${current_branch}?expand=1"
}

# Copy the diff of the current pull request
github_copy_diff() {
  validate_git_repo || return 1

  # Ensure the pull request number is provided
  if [[ -z "$1" ]]; then
    echo "Usage: github_copy_diff <pull_request_number>" >&2
    return 1
  fi

  # Check if the `gh` CLI is installed and authenticated
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed." >&2
    return 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: Not authenticated with GitHub CLI." >&2
    return 1
  fi

  set_clipboard_command || return 1

  # Copy the diff of the specified pull request to the clipboard
  gh pr diff "$1" | $clipboard_cmd || {
    echo "Error: Failed to copy diff to clipboard." >&2
    return 1
  }

  echo "Diff of pull request #$1 copied to clipboard."
}

# Get the GitHub repository URL in HTTPS format, removing any custom SSH host aliases
github_project_root() {
  local file_path=${1:-$(pwd)}
  local url=$(git -C "$file_path" config remote.origin.url)

  # Ensure the URL is non-empty
  if [[ -z "$url" ]]; then
    echo "Error: Unable to determine GitHub project root." >&2
    return 1
  fi

  # Escape special characters and transform URL
  echo "$url" |
    sed -E 's|git@([^:]+):(.+)|https://\1/\2|' | # Convert SSH to HTTPS
    sed -E 's|\.git$||' |                        # Remove `.git` suffix
    sed -E 's|github\.com-work|github.com|' |    # Normalize host alias
    sed -E 's|github\.com-personal|github.com|'  # Normalize host alias
}

# Open the current branch's view of a specific file or directory in GitHub
github_open_current_branch() {
  local file=${1:-""}
  local file_path=${2:-$(pwd)}
  local current_branch=$(git_current_branch "$file_path")
  local project_root=$(github_project_root "$file_path")
  local git_directory=$(git -C "$file_path" rev-parse --show-prefix)

  ${open_cmd} "${project_root}/tree/${current_branch}/${git_directory}${file}"
}

# Open the current GitHub repository in the default browser
github_open_current_repo() {
  local file_path=${1:-$(pwd)}
  local project_root=$(github_project_root "$file_path")

  if [[ -n "$project_root" ]]; then
    ${open_cmd} "${project_root}"
  else
    echo "Error: Unable to open GitHub project root." >&2
    return 1
  fi
}

# Get the GitHub username and repository name in the format "user/repo"
github_user_repo() {
  local file_path=${1:-$(pwd)}
  local project_root=$(github_project_root "$file_path")

  # Extract user/repo from the project root URL
  echo "$project_root" | sed -E 's|https://[^/]+/(.+)|\1|'
}
