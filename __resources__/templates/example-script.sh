#!/usr/bin/env bash

# Template for creating robust, production-ready bash scripts
#
# Features included:
# - Comprehensive error handling with proper exit codes
# - Color-coded logging with multiple levels (debug, info, warning, error, fatal)
# - Verbose/quiet modes for different output levels
# - Dependency checking and validation functions
# - Dry-run support for testing
# - User confirmation prompts for destructive operations
# - Terminal color detection and graceful fallback
# - Proper cleanup on both success and failure
# - Script metadata and version information
# - Robust argument parsing with long/short options
# - Helper functions for common operations
#
# Usage: Copy this template and customize the following sections:
# 1. Update script metadata (version, description)
# 2. Define required dependencies in check_dependencies()
# 3. Implement your main logic in the main() function
# 4. Update argument parsing for your specific needs
# 5. Add any custom validation or helper functions

set -euo pipefail

# ----------------------------#
# Script Metadata & Config    #
# ----------------------------#

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="1.0.0"
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

Usage: $SCRIPT_NAME <arg1> [options]

Arguments:
  ${BOLD}<arg1>${NC}            Example description

Options:
  ${BOLD}-d, --dry-run${NC}        Show what would happen without actually doing anything
  ${BOLD}-h, --help${NC}           Show this help message
  ${BOLD}-q, --quiet${NC}          Suppress non-error output
  ${BOLD}-v, --verbose${NC}        Enable verbose output
  ${BOLD}--version${NC}            Show version information

Examples:
  $SCRIPT_NAME arg1
  $SCRIPT_NAME arg1 --dry-run --verbose

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

# Check if script is run with sufficient privileges
check_root() {
  if [[ $EUID -eq 0 ]]; then
    log_warning "Running as root. This may not be necessary."
  fi
}

# Validate that required commands are available
check_dependencies() {
  local missing_deps=()

  # Add your required commands here
  local required_commands=("curl" "git")

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_fatal "Missing required dependencies: ${missing_deps[*]}"
  fi
}

# Validate file/directory exists
validate_path() {
  local path="$1"
  local type="${2:-file}" # file, directory, or any

  if [[ ! -e "$path" ]]; then
    log_fatal "Path does not exist: $path"
  fi

  case "$type" in
    file)
      [[ ! -f "$path" ]] && log_fatal "Not a file: $path"
      ;;
    directory)
      [[ ! -d "$path" ]] && log_fatal "Not a directory: $path"
      ;;
  esac
}

# Confirm action with user (useful for destructive operations)
confirm() {
  local message="${1:-Are you sure?}"
  local default="${2:-n}" # y or n

  if [[ "$default" == "y" ]]; then
    local prompt="$message [Y/n]: "
  else
    local prompt="$message [y/N]: "
  fi

  read -r -p "$prompt" response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    [nN][oO]|[nN]) return 1 ;;
    "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
    *) log_warning "Please answer yes or no."; confirm "$message" "$default" ;;
  esac
}

parse_arguments() {
  local arg1=""
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
        if [[ -z "$arg1" ]]; then
          arg1="$1"
        else
          log_error "Too many arguments: $1"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        shift
        ;;
    esac
  done

  # Handle remaining positional arguments after --
  while [[ $# -gt 0 ]]; do
    # Process additional positional arguments here
    shift
  done

  if [[ -z "$arg1" ]]; then
    log_error "arg1 is required"
    show_usage
    exit $EXIT_USAGE_ERROR
  fi

  # Validate arguments
  # Add your validation logic here

  # Export for use in other functions
  export ARG1="$arg1"
  export DRY_RUN="$dry_run"

  log_debug "Arguments parsed: ARG1=$ARG1, DRY_RUN=$DRY_RUN"
}

cleanup_on_error() {
  local exit_code=$?
  log_error "Script interrupted or failed (exit code: $exit_code)"

  # Add cleanup logic here
  # - Remove temporary files
  # - Restore backups
  # - Kill background processes
  # - etc.

  exit $exit_code
}

cleanup_on_exit() {
  local exit_code=$?

  # Cleanup logic that should run on both success and failure
  # - Remove temporary files
  # - Cleanup locks
  # - etc.

  if [[ $exit_code -eq 0 ]]; then
    log_debug "Script completed successfully"
  else
    log_debug "Script exited with code: $exit_code"
  fi
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

# ----------------------------#
# Business Logic              #
# ----------------------------#

do_the_thing() {
  log_info "Doing the thing with ARG1=$ARG1"

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
  # check_root  # Uncomment if you need to check for root privileges

  # Your main logic goes here
  log_info "Processing argument: $ARG1"

  # Example of using run_command
  # run_command "echo 'Hello, World!'" "Saying hello"

  do_the_thing

  # Example of confirmation for destructive operations
  # if ! confirm "This will delete files. Continue?"; then
  #   log_info "Operation cancelled by user"
  #   exit $EXIT_SUCCESS
  # fi

  log_success "All done! 🎉"
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
