#!/usr/bin/env bash

set -e

# ----------------------------#
# Constants & Default Values  #
# ----------------------------#

# Default Arguments
EXTERNAL=false
BRANCH_NAME=""
BASE_BRANCH=""
HELP=false

# Paths
ROOT_DIR=""
PARENT_DIR=""
SOURCE_PATH=""
TARGET_PATH=""
LOCAL_BRANCH=""

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  echo "Usage: git_create_worktree [--external|-e] [--from|-f <base-branch>] <branch-name>"
  echo "  --external, -e           Create worktree in external/ for inspecting remote branches"
  echo "  --from, -f <base-branch> Create new branch from specified base branch"
  echo "  --help, -h               Show this help message"
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help|-h)
        HELP=true
        shift
        ;;
      --external|-e)
        EXTERNAL=true
        shift
        ;;
      --from|-f)
        BASE_BRANCH="$2"
        shift 2
        ;;
      *)
        if [[ -z "$BRANCH_NAME" ]]; then
          BRANCH_NAME="$1"
        else
          echo "❌ Error: Multiple branch names provided"
          return 1
        fi
        shift
        ;;
    esac
  done
}

validate_arguments() {
  if [[ -z "$BRANCH_NAME" ]]; then
    echo "❌ Error: Branch name is required"
    show_usage
    return 1
  fi
}

initialize_paths() {
  ROOT_DIR=$(git rev-parse --show-toplevel)
  PARENT_DIR=$(dirname "$ROOT_DIR")
  SOURCE_PATH="$ROOT_DIR"

  if [[ "$EXTERNAL" == true ]]; then
    TARGET_PATH="$PARENT_DIR/external/$BRANCH_NAME"
    LOCAL_BRANCH="$BRANCH_NAME"
    echo "📁 Creating external worktree: $TARGET_PATH for remote branch '$BRANCH_NAME'"
  else
    TARGET_PATH="$PARENT_DIR/$BRANCH_NAME"
    LOCAL_BRANCH="jap/$BRANCH_NAME"
    echo "📁 Creating worktree: $TARGET_PATH from '$BRANCH_NAME'"
  fi
}

validate_target_path() {
  if [[ -e "$TARGET_PATH" ]]; then
    echo "❌ Error: Target path already exists at $TARGET_PATH"
    return 1
  fi
}

prepare_directories() {
  if [[ "$EXTERNAL" == true ]]; then
    mkdir -p "$PARENT_DIR/external"
  fi
}

fetch_remote_changes() {
  git -C "$SOURCE_PATH" fetch origin
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

# ----------------------------#
# Branch Creation Functions   #
# ----------------------------#

branch_exists_locally() {
  local branch="$1"
  git -C "$SOURCE_PATH" show-ref --verify --quiet "refs/heads/$branch"
}

branch_exists_on_remote() {
  local branch="$1"
  git -C "$SOURCE_PATH" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
}

create_worktree_from_base_branch() {
  echo "🌱 Creating new branch '$LOCAL_BRANCH' from '$BASE_BRANCH'"

  if branch_exists_locally "$BASE_BRANCH"; then
    echo "🔄 Using local base branch '$BASE_BRANCH'"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" -b "$LOCAL_BRANCH" "$BASE_BRANCH"
  elif branch_exists_on_remote "$BASE_BRANCH"; then
    echo "🔄 Using remote base branch 'origin/$BASE_BRANCH'"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" -b "$LOCAL_BRANCH" "origin/$BASE_BRANCH"
  else
    echo "❌ Error: Base branch '$BASE_BRANCH' not found locally or on origin"
    return 1
  fi
}

create_external_worktree() {
  if branch_exists_on_remote "$LOCAL_BRANCH"; then
    echo "🌱 Creating external worktree with local tracking branch for origin/$LOCAL_BRANCH"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" -b "$LOCAL_BRANCH" "origin/$LOCAL_BRANCH"
  elif branch_exists_locally "$LOCAL_BRANCH"; then
    echo "🔄 Using local branch '$LOCAL_BRANCH'"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" "$LOCAL_BRANCH"
  else
    echo "❌ Error: Branch '$LOCAL_BRANCH' not found locally or on origin"
    return 1
  fi
}

create_personal_worktree() {
  if branch_exists_locally "$LOCAL_BRANCH"; then
    echo "🔄 Using local branch '$LOCAL_BRANCH'"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" "$LOCAL_BRANCH"
  elif branch_exists_on_remote "$LOCAL_BRANCH"; then
    echo "🌱 Creating local branch '$LOCAL_BRANCH' from origin/$LOCAL_BRANCH"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" -b "$LOCAL_BRANCH" "origin/$LOCAL_BRANCH"
  else
    echo "🌱 Creating local branch '$LOCAL_BRANCH'"
    with_git_stash git -C "$SOURCE_PATH" worktree add "$TARGET_PATH" -b "$LOCAL_BRANCH"
  fi
}

create_worktree() {
  if [[ -n "$BASE_BRANCH" ]]; then
    create_worktree_from_base_branch
  elif [[ "$EXTERNAL" == true ]]; then
    create_external_worktree
  else
    create_personal_worktree
  fi
}

# ----------------------------#
# Symlink Functions           #
# ----------------------------#

get_untracked_files() {
  git -C . ls-files --others \
    --exclude storybook-static/ \
    --exclude node_modules \
    --exclude build \
    --exclude .DS_Store \
    --exclude dev-dist \
    --exclude "*/.*/"
}

create_symlink() {
  local file="$1"
  local source_file="$SOURCE_PATH/$file"
  local target_file="$TARGET_PATH/$file"
  local target_dir=$(dirname "$target_file")

  # Skip if target already exists
  if [[ -e "$target_file" ]]; then
    echo "  ⚠️  Skipping existing: $file"
    return 0
  fi

  # Create target directory structure
  mkdir -p "$target_dir"

  # Create symlink if source exists and is readable
  if [[ -f "$source_file" && -r "$source_file" ]]; then
    if ln -s "$source_file" "$target_file"; then
      echo "  🔗 Linked: $file"
    else
      echo "  ❌ Failed to link: $file"
    fi
  fi
}

create_symlinks() {
  echo "🔗 Creating symlinks for untracked files from $SOURCE_PATH → $TARGET_PATH"

  local untracked_files
  untracked_files=$(get_untracked_files)

  if [[ -n "$untracked_files" ]]; then
    while IFS= read -r file; do
      create_symlink "$file"
    done <<< "$untracked_files"
  else
    echo "  ℹ️  No untracked files to symlink"
  fi
}

change_to_worktree() {
  echo "✅ Worktree ready: $TARGET_PATH"

  cd "$TARGET_PATH" || {
    echo "❌ Error: Failed to change directory to $TARGET_PATH"
    return 1
  }
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  parse_arguments "$@" || {
    echo "❌ Failed to parse arguments"
    return 1
  }

  # Handle help separately
  if [[ "$HELP" == true ]]; then
    show_usage
    return 0
  fi

  validate_arguments || {
    echo "❌ Argument validation failed"
    return 1
  }

  initialize_paths || {
    echo "❌ Failed to initialize paths"
    return 1
  }

  validate_target_path || {
    echo "❌ Target path validation failed"
    return 1
  }

  prepare_directories || {
    echo "❌ Failed to prepare directories"
    return 1
  }

  echo "🔄 Fetching remote changes..."
  fetch_remote_changes || {
    echo "❌ Failed to fetch remote changes"
    return 1
  }

  echo "🌱 Creating worktree..."
  create_worktree || {
    echo "❌ Failed to create worktree"
    return 1
  }

  echo "🔗 Creating symlinks..."
  create_symlinks || {
    echo "❌ Failed to create symlinks (non-fatal)"
  }

  change_to_worktree || {
    echo "❌ Failed to change to worktree directory"
    return 1
  }

  echo "✅ Worktree creation completed successfully!"
  echo "📁 Location: $TARGET_PATH"
  echo "🌿 Branch: $LOCAL_BRANCH"
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
