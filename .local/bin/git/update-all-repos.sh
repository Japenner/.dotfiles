#!/usr/bin/env bash

# Update all Git repositories in a base directory
#
# Features:
# - Robust primary branch detection with fallbacks
# - Dirty working directory handling with stashing
# - Network connectivity checks
# - Progress tracking and summary reporting
# - Dry-run support for testing
# - Comprehensive error handling and logging
#
# Usage: update-all-repos.sh [options]

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
REPOS_DIR=""
FORCE_OVERWRITE=false
DRY_RUN=false

# Statistics tracking
TOTAL_REPOS=0
UPDATED_REPOS=0
SKIPPED_REPOS=0
FAILED_REPOS=0

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  printf "%b\n" "${BOLD}$SCRIPT_NAME${NC} v$SCRIPT_VERSION

Update all Git repositories in a directory by checking out their primary branch and pulling latest changes.

Usage: $SCRIPT_NAME [options]

Options:
  ${BOLD}-d, --dry-run${NC}        Show what would happen without actually doing anything
  ${BOLD}-f, --force${NC}          Force checkout even with uncommitted changes (stashes first)
  ${BOLD}-h, --help${NC}           Show this help message
  ${BOLD}-p, --path PATH${NC}      Base directory containing Git repositories (default: \$REPOS)
  ${BOLD}-q, --quiet${NC}          Suppress non-error output
  ${BOLD}-v, --verbose${NC}        Enable verbose output
  ${BOLD}--version${NC}            Show version information

Examples:
  $SCRIPT_NAME                                    # Update all repos in \$REPOS directory
  $SCRIPT_NAME --path ~/projects --dry-run        # Test updates in ~/projects
  $SCRIPT_NAME --force --verbose                  # Force updates with detailed output

Environment Variables:
  ${BOLD}REPOS${NC}               Base directory for repositories (required if --path not specified)

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
  local required_commands=("git" "find")

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_fatal "Missing required dependencies: ${missing_deps[*]}"
  fi
}

# Validate base directory
validate_repos_directory() {
  if [[ -z "$REPOS_DIR" ]]; then
    log_fatal "Repository directory not specified. Use --path or set \$REPOS environment variable."
  fi

  if [[ ! -d "$REPOS_DIR" ]]; then
    log_fatal "Repository directory does not exist: $REPOS_DIR"
  fi

  if [[ ! -r "$REPOS_DIR" ]]; then
    log_fatal "Cannot read repository directory: $REPOS_DIR"
  fi

  log_debug "Using repository directory: $REPOS_DIR"
}

# Enhanced function to find the primary branch with fallbacks
get_primary_branch() {
  local repo_path="$1"

  # Method 1: Check remote HEAD reference (most reliable)
  local primary_branch
  primary_branch=$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)

  if [[ -n "$primary_branch" ]]; then
    log_debug "Found primary branch via remote HEAD: $primary_branch"
    echo "$primary_branch"
    return 0
  fi

  # Method 2: Try to set remote HEAD and retry
  if git -C "$repo_path" remote set-head origin --auto >/dev/null 2>&1; then
    primary_branch=$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
    if [[ -n "$primary_branch" ]]; then
      log_debug "Found primary branch after setting remote HEAD: $primary_branch"
      echo "$primary_branch"
      return 0
    fi
  fi

  # Method 3: Fallback to common branch names
  local common_branches=("main" "master" "develop" "dev")
  for branch in "${common_branches[@]}"; do
    if git -C "$repo_path" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      log_debug "Found primary branch via fallback: $branch"
      echo "$branch"
      return 0
    fi
  done

  # Method 4: Use current branch as last resort
  primary_branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || true)
  if [[ -n "$primary_branch" ]]; then
    log_debug "Using current branch as primary: $primary_branch"
    echo "$primary_branch"
    return 0
  fi

  return 1
}

# Check if repository has uncommitted changes
has_uncommitted_changes() {
  local repo_path="$1"
  ! git -C "$repo_path" diff-index --quiet HEAD -- 2>/dev/null
}

# Check if repository has untracked files
has_untracked_files() {
  local repo_path="$1"
  [[ -n "$(git -C "$repo_path" ls-files --others --exclude-standard 2>/dev/null)" ]]
}

# Stash changes if they exist
stash_changes() {
  local repo_path="$1"
  local stash_created=false

  if has_uncommitted_changes "$repo_path" || has_untracked_files "$repo_path"; then
    log_info "Stashing local changes"
    if git -C "$repo_path" stash push --include-untracked --message "Auto-stash by $SCRIPT_NAME $(date)" >/dev/null 2>&1; then
      stash_created=true
      log_debug "Stash created successfully"
    else
      log_warning "Failed to create stash"
    fi
  fi

  echo "$stash_created"
}

# Restore stashed changes
restore_stash() {
  local repo_path="$1"
  local stash_created="$2"

  if [[ "$stash_created" == "true" ]]; then
    log_info "Restoring stashed changes"
    if git -C "$repo_path" stash pop >/dev/null 2>&1; then
      log_debug "Stash restored successfully"
    else
      log_warning "Failed to restore stash - you may need to resolve conflicts manually"
    fi
  fi
}

# Update a single repository
update_repository() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$repo_path")"

  log_info "Updating repository: ${BOLD}$repo_name${NC} ($repo_path)"
  ((TOTAL_REPOS++))

  # Validate it's a git repository
  if ! git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not a valid git repository: $repo_path"
    ((FAILED_REPOS++))
    return 1
  fi

  # Get primary branch
  local primary_branch
  if ! primary_branch=$(get_primary_branch "$repo_path"); then
    log_error "Could not determine primary branch for $repo_path"
    ((SKIPPED_REPOS++))
    return 1
  fi

  log_debug "Primary branch: $primary_branch"

  # Check for uncommitted changes
  local stash_created="false"
  if has_uncommitted_changes "$repo_path" || has_untracked_files "$repo_path"; then
    if [[ "$FORCE_OVERWRITE" == "true" ]]; then
      stash_created=$(stash_changes "$repo_path")
    else
      log_warning "Repository has uncommitted changes. Use --force to stash and continue, or commit/stash manually."
      ((SKIPPED_REPOS++))
      return 1
    fi
  fi

  # Fetch latest changes
  log_debug "Fetching from origin"
  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would fetch from origin"
  else
    if ! git -C "$repo_path" fetch origin >/dev/null 2>&1; then
      log_warning "Failed to fetch from origin (network/auth issue?)"
    fi
  fi

  # Checkout primary branch
  local current_branch
  current_branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || echo "detached")

  if [[ "$current_branch" != "$primary_branch" ]]; then
    log_debug "Switching from '$current_branch' to '$primary_branch'"
    if [[ "$DRY_RUN" == true ]]; then
      log_warning "[DRY RUN] Would checkout: $primary_branch"
    else
      if ! git -C "$repo_path" checkout "$primary_branch" >/dev/null 2>&1; then
        log_error "Failed to checkout $primary_branch"
        restore_stash "$repo_path" "$stash_created"
        ((FAILED_REPOS++))
        return 1
      fi
    fi
  fi

  # Pull latest changes
  log_debug "Pulling latest changes"
  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would pull latest changes"
    log_success "Would update successfully (dry-run)"
    ((UPDATED_REPOS++))
  else
    if git -C "$repo_path" pull >/dev/null 2>&1; then
      log_success "Updated successfully"
      ((UPDATED_REPOS++))
    else
      log_error "Failed to pull latest changes"
      restore_stash "$repo_path" "$stash_created"
      ((FAILED_REPOS++))
      return 1
    fi
  fi

  # Restore stashed changes if we created any
  if [[ "$DRY_RUN" != true ]]; then
    restore_stash "$repo_path" "$stash_created"
  fi

  return 0
}

parse_arguments() {
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
      -d|--dry-run)
        DRY_RUN=true
        shift
        ;;
      -f|--force)
        FORCE_OVERWRITE=true
        shift
        ;;
      -p|--path)
        if [[ -z "${2:-}" ]]; then
          log_error "--path requires a directory argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        REPOS_DIR="$2"
        shift 2
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
        log_error "Unexpected argument: $1"
        show_usage
        exit $EXIT_USAGE_ERROR
        ;;
    esac
  done

  # Set default repos directory if not provided
  if [[ -z "$REPOS_DIR" ]]; then
    REPOS_DIR="${REPOS:-}"
  fi

  log_debug "Arguments parsed: REPOS_DIR=$REPOS_DIR, DRY_RUN=${DRY_RUN:-false}, FORCE_OVERWRITE=$FORCE_OVERWRITE"
}

cleanup_on_exit() {
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_debug "Script completed successfully"
  else
    log_debug "Script exited with code: $exit_code"
  fi
}

show_summary() {
  if [[ $TOTAL_REPOS -gt 0 ]]; then
    log_info ""
    log_info "${BOLD}Summary:${NC}"
    log_info "  Total repositories: $TOTAL_REPOS"
    log_success "  Successfully updated: $UPDATED_REPOS"
    [[ $SKIPPED_REPOS -gt 0 ]] && log_warning "  Skipped: $SKIPPED_REPOS"
    [[ $FAILED_REPOS -gt 0 ]] && log_error "  Failed: $FAILED_REPOS"
  fi
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Parse and validate arguments first (before setting up traps)
  parse_arguments "$@"

  # Set up cleanup handler
  trap cleanup_on_exit EXIT

  # Initial setup
  log_debug "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  log_debug "Script directory: $SCRIPT_DIR"
  log_debug "Working directory: $(pwd)"

  # Pre-flight checks
  check_dependencies
  validate_repos_directory

  # Find all git repositories
  log_info "Scanning for Git repositories in: ${BOLD}$REPOS_DIR${NC}"

  local git_dirs=()
  while IFS= read -r -d '' git_dir; do
    git_dirs+=("$(dirname "$git_dir")")
  done < <(find "$REPOS_DIR" -type d -name ".git" -print0 2>/dev/null)

  if [[ ${#git_dirs[@]} -eq 0 ]]; then
    log_warning "No Git repositories found in $REPOS_DIR"
    exit $EXIT_SUCCESS
  fi

  log_info "Found ${#git_dirs[@]} Git repositories"

  # Update each repository
  for repo_path in "${git_dirs[@]}"; do
    update_repository "$repo_path" || true  # Continue on individual failures
  done

  # Show final summary
  show_summary

  if [[ $FAILED_REPOS -gt 0 ]]; then
    log_warning "Some repositories failed to update. Check the logs above for details."
    exit $EXIT_GENERAL_ERROR
  fi

  if [[ $DRY_RUN == true ]]; then
    log_success "Dry-run completed successfully! 🎉"
  else
    log_success "All repositories updated successfully! 🎉"
  fi
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
