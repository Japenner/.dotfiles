#!/usr/bin/env bash

# Git repository cloner with worktree structure and workspace setup
#
# Features:
# - Clones repositories into organized directory structure
# - Sets up VS Code workspace configuration
# - Proper error handling and cleanup
# - Dry-run support for testing
# - Verbose/quiet modes for different output levels
# - Validates dependencies and environment

set -euo pipefail

# ----------------------------#
# Script Metadata & Config    #
# ----------------------------#

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="2.0.0"
readonly PROJECTS_DIR="$(pwd)"
readonly DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
readonly CODE_EDITOR="${CODE_EDITOR:-code}"

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

Clone a Git repository with organized directory structure and workspace setup.

Usage: $SCRIPT_NAME <repo-url> [options]

Arguments:
  ${BOLD}<repo-url>${NC}            URL of the remote repository to clone

Options:
  ${BOLD}-n, --name <name>${NC}     Override repository name (default: extracted from URL)
  ${BOLD}-d, --dry-run${NC}         Show what would happen without actually doing anything
  ${BOLD}-h, --help${NC}            Show this help message
  ${BOLD}-q, --quiet${NC}           Suppress non-error output
  ${BOLD}-v, --verbose${NC}         Enable verbose output
  ${BOLD}--version${NC}             Show version information

Directory Structure:
  Repositories are cloned into: <current-dir>/<repo-name>/main/
  VS Code workspace created at: <current-dir>/<repo-name>/<repo-name>.code-workspace

Examples:
  $SCRIPT_NAME https://github.com/user/repo.git
  $SCRIPT_NAME https://github.com/user/repo.git --name my-project
  $SCRIPT_NAME https://github.com/user/repo.git --dry-run --verbose

For more information, see: https://github.com/japenner/.dotfiles/git/clone-to-worktree.sh"
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

# Extract and sanitize repository name from URL
get_repo_name_from_url() {
  local url="$1"
  basename -s .git "$url" | sed 's/[^a-zA-Z0-9._-]/_/g'
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

# Validate environment and required files
validate_environment() {
  log_debug "Validating environment"

  if ! command_exists "$CODE_EDITOR"; then
    log_warning "$CODE_EDITOR is not available - workspace will be created but not opened"
  fi

  if [[ ! -f "$DOTFILES/git/example.code-workspace" ]]; then
    log_fatal "Workspace template not found at $DOTFILES/git/example.code-workspace" $EXIT_GENERAL_ERROR
  fi

  log_debug "Environment validation complete"
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
  local repo_url=""
  local repo_name=""
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
      -n|--name)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires an argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        repo_name="$2"
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
        if [[ -z "$repo_url" ]]; then
          repo_url="$1"
        else
          log_error "Too many arguments: $1"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$repo_url" ]]; then
    log_error "Repository URL is required"
    show_usage
    exit $EXIT_USAGE_ERROR
  fi

  # Extract repo name if not provided
  if [[ -z "$repo_name" ]]; then
    repo_name=$(get_repo_name_from_url "$repo_url")
    if [[ -z "$repo_name" ]]; then
      log_fatal "Could not extract repository name from URL" $EXIT_GENERAL_ERROR
    fi
  fi

  # Validate repository name
  if [[ ! "$repo_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    log_fatal "Invalid repository name: $repo_name (only alphanumeric, dots, underscores, and hyphens allowed)" $EXIT_USAGE_ERROR
  fi

  # Export for use in other functions
  export REPO_URL="$repo_url"
  export REPO_NAME="$repo_name"
  export TARGET_PATH="$PROJECTS_DIR/$repo_name/main"
  export DRY_RUN="$dry_run"

  log_debug "Arguments parsed: REPO_URL=$REPO_URL, REPO_NAME=$REPO_NAME, DRY_RUN=$DRY_RUN"
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

setup_project_structure() {
  local base_dir="$PROJECTS_DIR/$REPO_NAME"

  log_debug "Setting up project structure"

  if [[ -d "$TARGET_PATH" ]]; then
    log_fatal "Target path '$TARGET_PATH' already exists" $EXIT_GENERAL_ERROR
  fi

  log_info "Creating project structure at $base_dir"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would create directory: $base_dir"
    return 0
  fi

  if ! mkdir -p "$base_dir"; then
    log_fatal "Failed to create project directory: $base_dir" $EXIT_PERMISSION_ERROR
  fi

  log_debug "Project structure created successfully"
}

clone_repository() {
  log_info "Cloning repository '$REPO_URL' into '$TARGET_PATH'"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would clone: $REPO_URL -> $TARGET_PATH"
    return 0
  fi

  if ! git clone "$REPO_URL" "$TARGET_PATH"; then
    log_fatal "Failed to clone repository" $EXIT_GENERAL_ERROR
  fi

  log_success "Repository cloned successfully"
}

setup_workspace() {
  local workspace_file="$PROJECTS_DIR/$REPO_NAME/$REPO_NAME.code-workspace"

  log_info "Setting up VS Code workspace"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would create workspace: $workspace_file"
    log_warning "[DRY RUN] Would open in $CODE_EDITOR"
    return 0
  fi

  if ! cp "$DOTFILES/git/example.code-workspace" "$workspace_file"; then
    log_fatal "Failed to copy workspace configuration" $EXIT_GENERAL_ERROR
  fi

  log_success "Workspace configuration created at $workspace_file"

  # Only try to open in editor if it's available
  if command_exists "$CODE_EDITOR"; then
    if "$CODE_EDITOR" "$workspace_file" 2>/dev/null; then
      log_success "Opened workspace in $CODE_EDITOR"
    else
      log_warning "Failed to open workspace in $CODE_EDITOR"
    fi
  else
    log_info "Workspace created but $CODE_EDITOR not available to open it"
  fi
}

cleanup_on_error() {
  local exit_code=$?
  log_error "Script interrupted or failed (exit code: $exit_code)"

  # Clean up partial clone if it exists
  if [[ -n "${TARGET_PATH:-}" && -d "$TARGET_PATH" && "$DRY_RUN" != true ]]; then
    log_info "Cleaning up partial clone at $TARGET_PATH"
    rm -rf "$TARGET_PATH"
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
  log_debug "Projects directory: $PROJECTS_DIR"
  log_debug "Dotfiles directory: $DOTFILES"

  # Pre-flight checks
  check_dependencies
  validate_environment

  # Execute main workflow
  setup_project_structure
  clone_repository
  setup_workspace

  log_success "Project '$REPO_NAME' set up successfully at $TARGET_PATH"
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
