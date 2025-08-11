#!/usr/bin/env bash

set -euo pipefail

# ----------------------------#
# Constants & Configuration   #
# ----------------------------#

readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECTS_DIR="$(pwd)"
readonly DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'
TEAL='\033[0;36m'
YELLOW='\033[1;33m'

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  cat << EOF
Usage: $SCRIPT_NAME <repo-url> [options]

Arguments:
  <repo-url>                URL of the remote repository to clone

Options:
  -n, --name <name>         Override repository name (default: extracted from URL)
  -h, --help                Show this help message

Examples:
  $SCRIPT_NAME https://github.com/user/repo.git
  $SCRIPT_NAME https://github.com/user/repo.git --name my-project
EOF
}

log_info() {
    echo -e "${TEAL}ℹ️ $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}" >&2
}

log_warning() {
  echo -e "${YELLOW}⚠️ $1${NC}"
}

get_repo_name_from_url() {
  local url="$1"
  basename -s .git "$url" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

validate_environment() {
  if ! command -v git >/dev/null 2>&1; then
    log_error "git is not installed or not in PATH"
    return 1
  fi

  if ! command -v $CODE_EDITOR >/dev/null 2>&1; then
    log_error "$CODE_EDITOR is not available"
    return 1
  fi

  if [[ ! -f "$DOTFILES/git/example.code-workspace" ]]; then
    log_error "Workspace template not found at $DOTFILES/git/example.code-workspace"
    return 1
  fi
}

parse_arguments() {
  local repo_url=""
  local repo_name=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_usage
        exit 0
        ;;
      -n|--name)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires an argument"
          show_usage
          return 1
        fi
        repo_name="$2"
        shift 2
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        return 1
        ;;
      *)
        if [[ -z "$repo_url" ]]; then
          repo_url="$1"
        else
          log_error "Too many arguments"
          show_usage
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$repo_url" ]]; then
    log_error "Repository URL is required"
    show_usage
    return 1
  fi

  # Extract repo name if not provided
  if [[ -z "$repo_name" ]]; then
    repo_name=$(get_repo_name_from_url "$repo_url")
    if [[ -z "$repo_name" ]]; then
      log_error "Could not extract repository name from URL"
      return 1
    fi
  fi

  # Export for use in other functions
  export REPO_URL="$repo_url"
  export REPO_NAME="$repo_name"
  export TARGET_PATH="$PROJECTS_DIR/$repo_name/main"
}

setup_project_structure() {
  local base_dir="$PROJECTS_DIR/$REPO_NAME"

  if [[ -d "$TARGET_PATH" ]]; then
    log_error "Target path '$TARGET_PATH' already exists"
    return 1
  fi

  log_info "Creating project structure at $base_dir"
  mkdir -p "$base_dir"
}

clone_repository() {
  log_info "Cloning repository '$REPO_URL' into '$TARGET_PATH'"

  if ! git clone "$REPO_URL" "$TARGET_PATH"; then
    log_error "Failed to clone repository"
    return 1
  fi

  log_success "Repository cloned successfully"
}

setup_workspace() {
  local workspace_file="$PROJECTS_DIR/$REPO_NAME/$REPO_NAME.code-workspace"

  log_info "Setting up VSCode workspace"

  if ! cp "$DOTFILES/git/example.code-workspace" "$workspace_file"; then
    log_error "Failed to copy workspace configuration"
    return 1
  fi

  log_success "Workspace configuration created"

  # if ! $CODE_EDITOR "$workspace_file"; then
  #   log_error "Failed to open workspace"
  #   return 1
  # fi

  log_success "Opened workspace in $CODE_EDITOR"
}

cleanup_on_error() {
  if [[ -n "${TARGET_PATH:-}" && -d "$TARGET_PATH" ]]; then
    log_info "Cleaning up partial clone at $TARGET_PATH"
    rm -rf "$TARGET_PATH"
  fi
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Set up error handling
  trap cleanup_on_error ERR

  # Parse and validate arguments
  parse_arguments "$@"

  # Validate environment
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
