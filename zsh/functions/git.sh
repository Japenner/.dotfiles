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

# Create a new git worktree and copy untracked files (like .env)
git_create_worktree() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: git_create_worktree <branch-name>"
    return 1
  fi

  local root_dir
  root_dir=$(git rev-parse --show-toplevel)
  local parent_dir
  parent_dir=$(dirname "$root_dir")
  local source_path="$root_dir"
  local target_path="$parent_dir/$branch_name"

  if [[ -e "$target_path" ]]; then
    echo "❌ Error: Target path already exists at $target_path"
    return 1
  fi

  echo "📁 Creating worktree: $target_path from '$branch_name'"

  git -C "$source_path" fetch origin

  # Determine whether to use local branch or origin fallback
  if git -C "$source_path" show-ref --verify --quiet "refs/heads/jap/$branch_name"; then
    echo "🔄 Using local branch 'jap/$branch_name'"
    with_git_stash git -C "$source_path" worktree add "$target_path" "jap/$branch_name" || return 1
  elif git -C "$source_path" ls-remote --exit-code --heads origin "jap/$branch_name" >/dev/null 2>&1; then
    echo "🌱 Creating local branch 'jap/$branch_name' from origin/jap/$branch_name"
    with_git_stash git -C "$source_path" worktree add "$target_path" -b "jap/$branch_name" "origin/jap/$branch_name" || return 1
  else
    echo "❌ Error: Branch 'jap/$branch_name' does not exist locally or remotely"
    return 1
  fi

  echo "📦 Copying untracked files from $source_path → $target_path"

  # Get untracked files, excluding .git directory and other ignored patterns
  local untracked_files
  # untracked_files=$(git -C "$source_path" ls-files --others --exclude-standard)
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
  echo "💡 Open with: code $target_path"
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
