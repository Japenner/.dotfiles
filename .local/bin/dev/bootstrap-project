#!/usr/bin/env bash

# Bootstrap Project - Flexible project environment setup
#
# Features:
# - Multiple configurable search paths with environment variable expansion
# - Flexible development environment detection (custom scripts, Makefile, docker)
# - Smart tmux session management with layout support
# - Configurable search depth and file patterns
# - Skip options for selective component setup
# - Comprehensive error handling and logging
# - Dry-run support for testing configurations
#
# Usage: bootstrap-project.sh [options]

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
DRY_RUN=false

# Configuration with environment variable overrides
SEARCH_DEPTH="${BOOTSTRAP_SEARCH_DEPTH:-3}"
SEARCH_PATHS="${BOOTSTRAP_SEARCH_PATHS:-$HOME/code:$HOME/projects:$HOME/workspace:$HOME/repos}"
FZF_PROMPT="${BOOTSTRAP_FZF_PROMPT:-Select project: }"
DOCKER_COMPOSE_FILES="${BOOTSTRAP_DOCKER_FILES:-docker-compose.yml:compose.yml:docker-compose.yaml:compose.yaml}"
DEV_SETUP_FILES="${BOOTSTRAP_DEV_FILES:-.ops/devup:scripts/dev:bin/dev:Makefile:justfile}"
TMUX_LAYOUT_FILES="${BOOTSTRAP_TMUX_FILES:-.tmux.layout:.tmux.conf:.tmux-layout}"

# Skip flags
SKIP_TMUX=false
SKIP_DOCKER=false
SKIP_DIRENV=false

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  printf "%b\n" "${BOLD}$SCRIPT_NAME${NC} v$SCRIPT_VERSION

Bootstrap Project - Flexible project environment setup

${BOLD}Usage:${NC} $SCRIPT_NAME [options]

${BOLD}Options:${NC}
  ${BOLD}-d, --depth DEPTH${NC}      Search depth for projects (default: $SEARCH_DEPTH)
  ${BOLD}-p, --paths PATHS${NC}      Colon-separated search paths (default: configurable)
  ${BOLD}--prompt PROMPT${NC}        fzf prompt text (default: \"$FZF_PROMPT\")
  ${BOLD}--no-tmux${NC}              Skip tmux session setup
  ${BOLD}--no-docker${NC}            Skip docker/compose setup
  ${BOLD}--no-direnv${NC}            Skip direnv environment loading
  ${BOLD}--dry-run${NC}              Show what would happen without executing
  ${BOLD}-h, --help${NC}             Show this help message
  ${BOLD}-q, --quiet${NC}            Suppress non-error output
  ${BOLD}-v, --verbose${NC}          Enable verbose output
  ${BOLD}--version${NC}              Show version information

${BOLD}Environment Variables:${NC}
  ${BOLD}BOOTSTRAP_SEARCH_DEPTH${NC}   Search depth (default: 3)
  ${BOLD}BOOTSTRAP_SEARCH_PATHS${NC}   Colon-separated search paths
  ${BOLD}BOOTSTRAP_FZF_PROMPT${NC}     fzf prompt text
  ${BOLD}BOOTSTRAP_DOCKER_FILES${NC}   Docker compose filenames to look for
  ${BOLD}BOOTSTRAP_DEV_FILES${NC}      Dev setup files to look for
  ${BOLD}BOOTSTRAP_TMUX_FILES${NC}     Tmux layout files to look for

${BOLD}Examples:${NC}
  $SCRIPT_NAME                                          # Use defaults
  $SCRIPT_NAME -d 5 -p \"\$HOME/work:\$HOME/personal\"  # Custom depth and paths
  $SCRIPT_NAME --no-tmux --no-docker                    # Skip tmux and docker setup
  $SCRIPT_NAME --dry-run --verbose                      # Test configuration

${BOLD}Default Search Paths:${NC}
  $SEARCH_PATHS

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
  local required_commands=("fd" "fzf")

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_fatal "Missing required dependencies: ${missing_deps[*]}"
  fi

  log_debug "All required dependencies found: ${required_commands[*]}"
}

# Validate and expand search paths
validate_search_paths() {
  local -a search_paths=()
  IFS=':' read -ra path_array <<< "$SEARCH_PATHS"

  for path in "${path_array[@]}"; do
    # Expand environment variables in paths
    local expanded_path
    expanded_path=$(eval echo "$path")
    if [[ -d "$expanded_path" ]]; then
      search_paths+=("$expanded_path")
      log_debug "Valid search path: $expanded_path"
    else
      log_warning "Search path '$expanded_path' does not exist, skipping..."
    fi
  done

  if [[ ${#search_paths[@]} -eq 0 ]]; then
    log_fatal "No valid search paths found. Please check BOOTSTRAP_SEARCH_PATHS or use -p option."
  fi

  echo "${search_paths[@]}"
}

# Select project using fzf
select_project() {
  local -a search_paths=("$@")

  log_info "Searching for projects in: ${search_paths[*]}"
  log_info "Search depth: $SEARCH_DEPTH"

  # Build fd command
  local fd_args=()
  for path in "${search_paths[@]}"; do
    fd_args+=("$path")
  done

  # Select project directory
  local selected_project
  if ! selected_project="$(fd . "${fd_args[@]}" -t d -d "$SEARCH_DEPTH" | fzf --prompt="$FZF_PROMPT")"; then
    log_error "No project selected"
    return 1
  fi

  # Validate selected directory
  if [[ ! -d "$selected_project" ]]; then
    log_fatal "Selected directory '$selected_project' no longer exists"
  fi

  echo "$selected_project"
}

# Setup direnv environment
setup_direnv() {
  if [[ "$SKIP_DIRENV" == "true" ]]; then
    log_debug "Skipping direnv setup (--no-direnv specified)"
    return 0
  fi

  if ! command_exists direnv; then
    log_debug "direnv not found, skipping environment setup"
    return 0
  fi

  log_info "Loading direnv environment..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY RUN] Would load direnv environment"
  else
    eval "$(direnv export bash)" || log_warning "direnv failed to load environment"
  fi
}

# Setup development environment
setup_development_environment() {
  if [[ "$SKIP_DOCKER" == "true" ]]; then
    log_debug "Skipping development environment setup (--no-docker specified)"
    return 0
  fi

  log_info "Looking for development environment setup..."

  # Check for custom dev setup files first
  local dev_setup_found=false
  IFS=':' read -ra dev_files <<< "$DEV_SETUP_FILES"

  for dev_file in "${dev_files[@]}"; do
    if [[ -f "$dev_file" ]]; then
      log_debug "Found dev setup file: $dev_file"

      if [[ -x "$dev_file" ]]; then
        log_info "Running $dev_file..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would execute: ./$dev_file"
        else
          "./$dev_file" || log_warning "$dev_file failed"
        fi
        dev_setup_found=true
        break
      elif [[ "$dev_file" == "Makefile" ]] && command_exists make; then
        log_info "Running make (found Makefile)..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would execute: make"
        else
          make || log_warning "make failed"
        fi
        dev_setup_found=true
        break
      elif [[ "$dev_file" == "justfile" ]] && command_exists just; then
        log_info "Running just (found justfile)..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would execute: just"
        else
          just || log_warning "just failed"
        fi
        dev_setup_found=true
        break
      fi
    fi
  done

  # Fallback to docker compose if no custom setup found
  if [[ "$dev_setup_found" == "false" ]]; then
    local docker_compose_found=false
    IFS=':' read -ra docker_files <<< "$DOCKER_COMPOSE_FILES"

    for docker_file in "${docker_files[@]}"; do
      if [[ -f "$docker_file" ]]; then
        log_info "Starting docker compose ($docker_file)..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would execute: docker compose up -d"
        else
          docker compose up -d || log_warning "docker compose failed"
        fi
        docker_compose_found=true
        break
      fi
    done

    if [[ "$docker_compose_found" == "false" ]]; then
      log_info "No development environment configuration found"
      log_debug "Looked for: ${DEV_SETUP_FILES//:/, }, ${DOCKER_COMPOSE_FILES//:/, }"
    fi
  fi
}

# Setup tmux session
setup_tmux_session() {
  if [[ "$SKIP_TMUX" == "true" ]]; then
    log_debug "Skipping tmux setup (--no-tmux specified)"
    return 0
  fi

  local project_path="$1"
  local tmux_layout_found=false
  local session_name
  session_name="$(basename "$project_path")"

  IFS=':' read -ra tmux_files <<< "$TMUX_LAYOUT_FILES"

  for tmux_file in "${tmux_files[@]}"; do
    if [[ -f "$tmux_file" ]]; then
      tmux_layout_found=true
      log_debug "Found tmux layout file: $tmux_file"

      if [[ -n "${TMUX:-}" ]]; then
        log_info "Already inside tmux. Sourcing layout ($tmux_file) in current session..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would execute: tmux source-file $tmux_file"
        else
          tmux source-file "$tmux_file" || log_warning "Failed to source tmux layout"
        fi
      else
        log_info "Starting new tmux session '$session_name' with layout ($tmux_file)..."
        if [[ "$DRY_RUN" == "true" ]]; then
          log_warning "[DRY RUN] Would start tmux session: $session_name"
        else
          # Check if session already exists
          if tmux has-session -t "$session_name" 2>/dev/null; then
            log_info "Session '$session_name' already exists, attaching..."
            tmux attach-session -t "$session_name"
          else
            tmux new-session -d -s "$session_name" \; source-file "$tmux_file" \; attach || {
              log_warning "Failed to start tmux session with layout, starting regular session..."
              tmux new-session -s "$session_name" || log_warning "Failed to start tmux"
            }
          fi
        fi
      fi
      break
    fi
  done

  if [[ "$tmux_layout_found" == "false" ]]; then
    log_debug "No tmux layout found. Looked for: ${TMUX_LAYOUT_FILES//:/, }"
  fi
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
      -d|--depth)
        if [[ -z "${2:-}" ]]; then
          log_error "--depth requires a numeric argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        SEARCH_DEPTH="$2"
        shift 2
        ;;
      -p|--paths)
        if [[ -z "${2:-}" ]]; then
          log_error "--paths requires a colon-separated path argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        SEARCH_PATHS="$2"
        shift 2
        ;;
      --prompt)
        if [[ -z "${2:-}" ]]; then
          log_error "--prompt requires a string argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        FZF_PROMPT="$2"
        shift 2
        ;;
      --no-tmux)
        SKIP_TMUX=true
        shift
        ;;
      --no-docker)
        SKIP_DOCKER=true
        shift
        ;;
      --no-direnv)
        SKIP_DIRENV=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
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
        log_error "Unexpected argument: $1"
        show_usage
        exit $EXIT_USAGE_ERROR
        ;;
    esac
  done

  # Validate search depth is numeric
  if ! [[ "$SEARCH_DEPTH" =~ ^[0-9]+$ ]]; then
    log_fatal "Search depth must be a positive integer: $SEARCH_DEPTH"
  fi

  log_debug "Arguments parsed:"
  log_debug "  SEARCH_DEPTH=$SEARCH_DEPTH"
  log_debug "  SEARCH_PATHS=$SEARCH_PATHS"
  log_debug "  FZF_PROMPT=$FZF_PROMPT"
  log_debug "  SKIP_TMUX=$SKIP_TMUX"
  log_debug "  SKIP_DOCKER=$SKIP_DOCKER"
  log_debug "  SKIP_DIRENV=$SKIP_DIRENV"
  log_debug "  DRY_RUN=$DRY_RUN"
}

cleanup_on_error() {
  local exit_code=$?
  log_error "Script interrupted or failed (exit code: $exit_code)"
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

  # Validate and get search paths
  local search_paths_string
  search_paths_string=$(validate_search_paths)
  local -a search_paths
  read -ra search_paths <<< "$search_paths_string"

  # Select project
  local selected_project
  if ! selected_project=$(select_project "${search_paths[@]}"); then
    log_error "No project selected. Exiting."
    exit $EXIT_GENERAL_ERROR
  fi

  log_info "Entering project: ${BOLD}$(basename "$selected_project")${NC} ($selected_project)"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY RUN] Would change directory to: $selected_project"
  else
    cd "$selected_project" || log_fatal "Failed to change to directory '$selected_project'"
  fi

  # Setup project environment
  setup_direnv
  setup_development_environment
  setup_tmux_session "$selected_project"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_success "Dry-run completed! 🎉"
  else
    log_success "Project setup complete! 🎉"
  fi

  log_info "Current directory: $(pwd)"
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
