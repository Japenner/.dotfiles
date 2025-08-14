#!/usr/bin/env bash

# Git worktree creation script with advanced features
#
# Features:
# - Creates git worktrees for branches with intelligent branch handling
# - Supports external worktrees for inspecting remote branches
# - Creates symlinks for untracked files between worktrees
# - Comprehensive error handling and cleanup
# - Dry-run support for testing
# - Verbose/quiet modes for different output levels
# - Proper validation and dependency checking

set -euo pipefail

# ----------------------------#
# Script Metadata & Config    #
# ----------------------------#

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="2.0.0"
readonly DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_USAGE_ERROR=2
readonly EXIT_PERMISSION_ERROR=126
readonly EXIT_COMMAND_NOT_FOUND=127

# Colors for output (check if terminal supports colors)
if [[ -t 1 ]]; then
  readonly BLUE='\033[0;34m'
  readonly GREEN='\033[0;32m'
  readonly NC='\033[0m' # No Color
  readonly RED='\033[0;31m'
  readonly TEAL='\033[0;36m'
  readonly YELLOW='\033[1;33m'
  readonly BOLD='\033[1m'
  readonly DIM='\033[2m'
else
  readonly BLUE=''
  readonly GREEN=''
  readonly NC=''
  readonly RED=''
  readonly TEAL=''
  readonly YELLOW=''
  readonly BOLD=''
  readonly DIM=''
fi

# Global variables
VERBOSE=false
QUIET=false

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  printf "%b\n" "${BOLD}$SCRIPT_NAME${NC} v$SCRIPT_VERSION

Create git worktrees with intelligent branch handling and symlink management.

Usage: $SCRIPT_NAME <branch-name> [options]

Arguments:
  ${BOLD}<branch-name>${NC}        Name of the branch to create worktree for

Options:
  ${BOLD}-e, --external${NC}       Create worktree in external/ for inspecting remote branches
  ${BOLD}-f, --from <base>${NC}    Create new branch from specified base branch
  ${BOLD}-d, --dry-run${NC}        Show what would happen without actually doing anything
  ${BOLD}-h, --help${NC}           Show this help message
  ${BOLD}-q, --quiet${NC}          Suppress non-error output
  ${BOLD}-v, --verbose${NC}        Enable verbose output
  ${BOLD}--version${NC}            Show version information

Examples:
  $SCRIPT_NAME feature-branch
  $SCRIPT_NAME bugfix --from main
  $SCRIPT_NAME remote-branch --external
  $SCRIPT_NAME new-feature --dry-run --verbose

For more information, see: https://github.com/japenner/.dotfiles"
}

show_version() {
  echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

# Logging functions with level support
log_debug() {
  [[ "$VERBOSE" == true ]] && echo -e "${DIM}🔍 DEBUG: $1${NC}" >&2 || true
}

log_info() {
  [[ "$QUIET" == false ]] && echo -e "${TEAL}ℹ️  $1${NC}" || true
}

log_success() {
  [[ "$QUIET" == false ]] && echo -e "${GREEN}✅ $1${NC}" || true
}

log_error() {
  echo -e "${RED}❌ ERROR: $1${NC}" >&2
}

log_warning() {
  [[ "$QUIET" == false ]] && echo -e "${YELLOW}⚠️  WARNING: $1${NC}" >&2 || true
}

log_fatal() {
  echo -e "${RED}💀 FATAL: $1${NC}" >&2
  exit "${2:-$EXIT_GENERAL_ERROR}"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validate that required commands are available
check_dependencies() {
  local missing_deps=()
  local required_commands=("git")

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_fatal "Missing required dependencies: ${missing_deps[*]}" $EXIT_COMMAND_NOT_FOUND
  fi
}

# Validate we're in a git repository
validate_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_fatal "Not in a git repository" $EXIT_GENERAL_ERROR
  fi
}

# Validate file/directory exists
validate_path() {
  local path="$1"
  local type="${2:-file}" # file, directory, or any

  if [[ ! -e "$path" ]]; then
    log_fatal "Path does not exist: $path" $EXIT_GENERAL_ERROR
  fi

  case "$type" in
    file)
      [[ ! -f "$path" ]] && log_fatal "Not a file: $path" $EXIT_GENERAL_ERROR
      ;;
    directory)
      [[ ! -d "$path" ]] && log_fatal "Not a directory: $path" $EXIT_GENERAL_ERROR
      ;;
  esac
}

parse_arguments() {
  local branch_name=""
  local external=false
  local base_branch=""
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_usage
        exit $EXIT_SUCCESS
        ;;
      --version)
        show_version
        exit $EXIT_SUCCESS
        ;;
      -e|--external)
        external=true
        shift
        ;;
      -f|--from)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires an argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        base_branch="$2"
        shift 2
        ;;
      -d|--dry-run)
        dry_run=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -q|--quiet)
        QUIET=true
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        exit $EXIT_USAGE_ERROR
        ;;
      *)
        if [[ -z "$branch_name" ]]; then
          branch_name="$1"
        else
          log_error "Too many arguments: $1"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$branch_name" ]]; then
    log_error "Branch name is required"
    show_usage
    exit $EXIT_USAGE_ERROR
  fi

  # Validate branch name
  if [[ ! "$branch_name" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    log_fatal "Invalid branch name: $branch_name (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" $EXIT_USAGE_ERROR
  fi

  # Export for use in other functions
  export BRANCH_NAME="$branch_name"
  export EXTERNAL="$external"
  export BASE_BRANCH="$base_branch"
  export DRY_RUN="$dry_run"

  log_debug "Arguments parsed: BRANCH_NAME=$BRANCH_NAME, EXTERNAL=$EXTERNAL, BASE_BRANCH=$BASE_BRANCH, DRY_RUN=$DRY_RUN"
}

# Function to run commands with optional dry-run support
run_command() {
  local cmd="$1"
  local description="${2:-Running command}"

  log_info "$description"
  log_debug "Command: $cmd"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would execute: $cmd"
    return 0
  fi

  if ! eval "$cmd"; then
    log_fatal "Command failed: $cmd" $EXIT_GENERAL_ERROR
  fi
}

initialize_paths() {
  local root_dir parent_dir source_path target_path local_branch

  root_dir=$(git rev-parse --show-toplevel)
  parent_dir=$(dirname "$root_dir")
  source_path="$root_dir"

  if [[ "$EXTERNAL" == true ]]; then
    target_path="$parent_dir/external/$BRANCH_NAME"
    local_branch="$BRANCH_NAME"
    log_info "Creating external worktree: $target_path for remote branch '$BRANCH_NAME'"
  else
    target_path="$parent_dir/$BRANCH_NAME"
    local_branch="jap/$BRANCH_NAME"
    log_info "Creating worktree: $target_path from '$BRANCH_NAME'"
  fi

  # Export for use in other functions
  export ROOT_DIR="$root_dir"
  export PARENT_DIR="$parent_dir"
  export SOURCE_PATH="$source_path"
  export TARGET_PATH="$target_path"
  export LOCAL_BRANCH="$local_branch"

  log_debug "Paths initialized: ROOT_DIR=$ROOT_DIR, TARGET_PATH=$TARGET_PATH, LOCAL_BRANCH=$LOCAL_BRANCH"
}

validate_target_path() {
  if [[ -e "$TARGET_PATH" ]]; then
    log_fatal "Target path already exists at $TARGET_PATH" $EXIT_GENERAL_ERROR
  fi
}

prepare_directories() {
  if [[ "$EXTERNAL" == true ]]; then
    log_info "Creating external directory structure"
    if [[ "$DRY_RUN" == true ]]; then
      log_warning "[DRY RUN] Would create directory: $PARENT_DIR/external"
    else
      mkdir -p "$PARENT_DIR/external"
    fi
  fi
}

fetch_remote_changes() {
  log_info "Fetching remote changes"
  run_command "git -C '$SOURCE_PATH' fetch origin" "Fetching from origin"
}

# Wrapper function to stash local changes before running a function and restore them afterward
with_git_stash() {
  local stash_needed=false

  log_debug "Checking for local changes to stash"

  # Check for local changes and stash them if any exist
  if ! git diff --quiet || ! git diff --staged --quiet; then
    log_info "Stashing local changes"
    if [[ "$DRY_RUN" == true ]]; then
      log_warning "[DRY RUN] Would stash local changes"
      stash_needed=true
    else
      if ! git stash -u; then
        log_fatal "Failed to stash changes" $EXIT_GENERAL_ERROR
      fi
      stash_needed=true
    fi
  fi

  # Execute the specified function
  "$@"
  local result=$?

  # If there was a stash, pop it to restore local changes
  if [[ "$stash_needed" == true ]]; then
    log_info "Restoring stashed changes"
    if [[ "$DRY_RUN" == true ]]; then
      log_warning "[DRY RUN] Would restore stashed changes"
    else
      if ! git stash pop; then
        log_error "Failed to pop the stash. You may need to resolve conflicts manually."
        return 1
      fi
    fi
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
  log_info "Creating new branch '$LOCAL_BRANCH' from '$BASE_BRANCH'"

  if branch_exists_locally "$BASE_BRANCH"; then
    log_info "Using local base branch '$BASE_BRANCH'"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' -b '$LOCAL_BRANCH' '$BASE_BRANCH'" "Creating worktree from local branch"
  elif branch_exists_on_remote "$BASE_BRANCH"; then
    log_info "Using remote base branch 'origin/$BASE_BRANCH'"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' -b '$LOCAL_BRANCH' 'origin/$BASE_BRANCH'" "Creating worktree from remote branch"
  else
    log_fatal "Base branch '$BASE_BRANCH' not found locally or on origin" $EXIT_GENERAL_ERROR
  fi
}

create_external_worktree() {
  if branch_exists_on_remote "$LOCAL_BRANCH"; then
    log_info "Creating external worktree with local tracking branch for origin/$LOCAL_BRANCH"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' -b '$LOCAL_BRANCH' 'origin/$LOCAL_BRANCH'" "Creating external worktree from remote"
  elif branch_exists_locally "$LOCAL_BRANCH"; then
    log_info "Using local branch '$LOCAL_BRANCH'"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' '$LOCAL_BRANCH'" "Creating external worktree from local branch"
  else
    log_fatal "Branch '$LOCAL_BRANCH' not found locally or on origin" $EXIT_GENERAL_ERROR
  fi
}

create_personal_worktree() {
  if branch_exists_locally "$LOCAL_BRANCH"; then
    log_info "Using local branch '$LOCAL_BRANCH'"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' '$LOCAL_BRANCH'" "Creating worktree from local branch"
  elif branch_exists_on_remote "$LOCAL_BRANCH"; then
    log_info "Creating local branch '$LOCAL_BRANCH' from origin/$LOCAL_BRANCH"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' -b '$LOCAL_BRANCH' 'origin/$LOCAL_BRANCH'" "Creating worktree with tracking branch"
  else
    log_info "Creating local branch '$LOCAL_BRANCH'"
    run_command "with_git_stash git -C '$SOURCE_PATH' worktree add '$TARGET_PATH' -b '$LOCAL_BRANCH'" "Creating worktree with new branch"
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
    log_warning "Skipping existing: $file"
    return 0
  fi

  log_debug "Processing symlink for: $file"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would create directory: $target_dir"
    log_warning "[DRY RUN] Would link: $source_file -> $target_file"
    return 0
  fi

  # Create target directory structure
  if ! mkdir -p "$target_dir"; then
    log_error "Failed to create directory: $target_dir"
    return 1
  fi

  # Create symlink if source exists and is readable
  if [[ -f "$source_file" && -r "$source_file" ]]; then
    if ln -s "$source_file" "$target_file"; then
      log_info "Linked: $file"
    else
      log_error "Failed to link: $file"
      return 1
    fi
  else
    log_warning "Source file not found or not readable: $source_file"
  fi
}

create_symlinks() {
  log_info "Creating symlinks for untracked files from $SOURCE_PATH → $TARGET_PATH"

  local untracked_files
  untracked_files=$(get_untracked_files)

  if [[ -n "$untracked_files" ]]; then
    while IFS= read -r file; do
      create_symlink "$file" || log_warning "Failed to create symlink for: $file"
    done <<< "$untracked_files"
  else
    log_info "No untracked files to symlink"
  fi
}

change_to_worktree() {
  log_success "Worktree ready: $TARGET_PATH"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would change directory to: $TARGET_PATH"
    return 0
  fi

  if ! cd "$TARGET_PATH"; then
    log_fatal "Failed to change directory to $TARGET_PATH" $EXIT_GENERAL_ERROR
  fi
}

# Cleanup functions
cleanup_on_error() {
  local exit_code=$?
  log_error "Script interrupted or failed (exit code: $exit_code)"

  # Clean up partial worktree if it exists
  if [[ -n "${TARGET_PATH:-}" && -d "$TARGET_PATH" && "$DRY_RUN" != true ]]; then
    log_info "Cleaning up partial worktree at $TARGET_PATH"
    git worktree remove "$TARGET_PATH" --force 2>/dev/null || rm -rf "$TARGET_PATH"
  fi

  exit $exit_code
}

cleanup_on_exit() {
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_debug "Script completed successfully"
  else
    log_debug "Script exited with code: $exit_code"
  fi
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Parse and validate arguments first (before setting up traps)
  parse_arguments "$@"

  # Set up error handling and cleanup after argument parsing
  trap cleanup_on_error ERR INT TERM
  trap cleanup_on_exit EXIT

  # Initial setup
  log_debug "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  log_debug "Script directory: $SCRIPT_DIR"
  log_debug "Working directory: $(pwd)"

  # Pre-flight checks
  check_dependencies
  validate_git_repo

  # Initialize paths and validate target
  initialize_paths
  validate_target_path

  # Prepare directories if needed
  prepare_directories

  # Fetch remote changes
  fetch_remote_changes

  # Create the worktree
  log_info "Creating worktree..."
  create_worktree

  # Create symlinks for untracked files
  log_info "Creating symlinks..."
  create_symlinks

  # Change to the new worktree directory
  change_to_worktree

  # Success message
  log_success "Worktree creation completed successfully!"
  log_info "Location: $TARGET_PATH"
  log_info "Branch: $LOCAL_BRANCH"
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
