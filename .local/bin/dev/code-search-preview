#!/usr/bin/env bash

# Code Search Preview - Interactive code search with live preview
#
# Features:
# - Fast regex search using ripgrep
# - Interactive selection with fzf
# - Live syntax-highlighted preview with bat
# - Configurable editor integration
# - Multiple search modes and options
#
# Usage: code-search-preview [options] "<search_query>"

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
SEARCH_PATH="${CODE_SEARCH_PATH:-$(pwd)}"
EDITOR_CMD="${CODE_SEARCH_EDITOR:-${EDITOR:-code}}"
PREVIEW_LINES="${CODE_SEARCH_PREVIEW_LINES:-10}"
SEARCH_HIDDEN="${CODE_SEARCH_HIDDEN:-true}"
CASE_SENSITIVE="${CODE_SEARCH_CASE_SENSITIVE:-false}"
EXCLUDE_PATTERNS="${CODE_SEARCH_EXCLUDE:-}"
FILE_TYPES="${CODE_SEARCH_TYPES:-}"

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  printf "%b\n" "${BOLD}$SCRIPT_NAME${NC} v$SCRIPT_VERSION

Interactive code search tool with live preview and editor integration.

${BOLD}Usage:${NC} $SCRIPT_NAME [options] \"<search_query>\"

${BOLD}Arguments:${NC}
  ${BOLD}<search_query>${NC}          Text/regex pattern to search for

${BOLD}Options:${NC}
  ${BOLD}-p, --path PATH${NC}         Search path (default: current directory)
  ${BOLD}-e, --editor EDITOR${NC}     Editor command (default: \$EDITOR or 'code')
  ${BOLD}-l, --lines LINES${NC}       Preview context lines (default: $PREVIEW_LINES)
  ${BOLD}-t, --type TYPES${NC}        File types to search (e.g., 'js,ts,py')
  ${BOLD}-x, --exclude PATTERNS${NC}  Exclude patterns (comma-separated)
  ${BOLD}--case-sensitive${NC}        Enable case-sensitive search
  ${BOLD}--no-hidden${NC}             Skip hidden files and directories
  ${BOLD}--dry-run${NC}               Show search command without executing
  ${BOLD}-h, --help${NC}              Show this help message
  ${BOLD}-q, --quiet${NC}             Suppress non-error output
  ${BOLD}-v, --verbose${NC}           Enable verbose output
  ${BOLD}--version${NC}               Show version information

${BOLD}Environment Variables:${NC}
  ${BOLD}CODE_SEARCH_PATH${NC}         Default search path
  ${BOLD}CODE_SEARCH_EDITOR${NC}       Default editor command
  ${BOLD}CODE_SEARCH_PREVIEW_LINES${NC} Preview context lines (default: 10)
  ${BOLD}CODE_SEARCH_HIDDEN${NC}       Search hidden files (default: true)
  ${BOLD}CODE_SEARCH_CASE_SENSITIVE${NC} Case sensitivity (default: false)
  ${BOLD}CODE_SEARCH_EXCLUDE${NC}      Default exclude patterns
  ${BOLD}CODE_SEARCH_TYPES${NC}        Default file types

${BOLD}Examples:${NC}
  $SCRIPT_NAME \"function getName\"              # Search for function
  $SCRIPT_NAME -t js,ts \"import.*react\"        # Search in JS/TS files
  $SCRIPT_NAME -x \"test,spec\" \"TODO\"          # Exclude test files
  $SCRIPT_NAME --case-sensitive \"Error\"        # Case-sensitive search
  $SCRIPT_NAME -p ~/projects \"class.*Component\" # Search specific path

${BOLD}Dependencies:${NC}
  - ripgrep (rg): Fast text search
  - fzf: Interactive fuzzy finder
  - bat: Syntax-highlighted file viewer
  - Editor: VS Code, vim, emacs, etc.

${BOLD}Interactive Controls:${NC}
  - ↑/↓: Navigate results
  - Enter: Open file at line in editor
  - Ctrl+C: Cancel search
  - Tab: Toggle preview

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

# Check all required dependencies
check_dependencies() {
  local missing_deps=()

  if ! command_exists rg; then
    missing_deps+=("ripgrep (rg)")
  fi

  if ! command_exists fzf; then
    missing_deps+=("fzf")
  fi

  if ! command_exists bat; then
    missing_deps+=("bat")
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_fatal "Missing required dependencies: ${missing_deps[*]}

Install instructions:
  macOS: brew install ripgrep fzf bat
  Ubuntu/Debian: apt install ripgrep fzf bat
  Arch: pacman -S ripgrep fzf bat"
  fi

  log_debug "All dependencies found: rg, fzf, bat"
}

# Validate search path
validate_search_path() {
  local path="$1"

  if [[ ! -d "$path" ]]; then
    log_fatal "Search path does not exist: $path"
  fi

  if [[ ! -r "$path" ]]; then
    log_fatal "Search path is not readable: $path"
  fi

  log_debug "Validated search path: $path"
}

# Build ripgrep command with options
build_rg_command() {
  local query="$1"
  local rg_cmd=("rg" "--line-number" "--color=never")

  # Add hidden files option
  if [[ "$SEARCH_HIDDEN" == "true" ]]; then
    rg_cmd+=("--hidden")
    log_debug "Searching hidden files"
  fi

  # Add case sensitivity option
  if [[ "$CASE_SENSITIVE" == "false" ]]; then
    rg_cmd+=("-i")
    log_debug "Case-insensitive search"
  else
    log_debug "Case-sensitive search"
  fi

  # Add file type restrictions
  if [[ -n "$FILE_TYPES" ]]; then
    IFS=',' read -ra types <<< "$FILE_TYPES"
    for type in "${types[@]}"; do
      rg_cmd+=("--type" "$type")
    done
    log_debug "File types: $FILE_TYPES"
  fi

  # Add exclude patterns
  if [[ -n "$EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra patterns <<< "$EXCLUDE_PATTERNS"
    for pattern in "${patterns[@]}"; do
      rg_cmd+=("--glob" "!*$pattern*")
    done
    log_debug "Exclude patterns: $EXCLUDE_PATTERNS"
  fi

  # Add the query and search path
  rg_cmd+=("$query" "$SEARCH_PATH")

  echo "${rg_cmd[@]}"
}

# Build fzf command with preview
build_fzf_command() {
  local preview_cmd="bat --style=numbers --color=always {1} --line-range {2}:+$PREVIEW_LINES"
  local fzf_cmd=(
    "fzf"
    "--delimiter" ":"
    "--nth" "3.."
    "--preview" "$preview_cmd"
    "--preview-window" "right:50%"
    "--bind" "ctrl-/:toggle-preview"
    "--header" "Enter: Open in editor | Ctrl+/: Toggle preview | Ctrl+C: Cancel"
  )

  echo "${fzf_cmd[@]}"
}

# Execute the search pipeline
execute_search() {
  local query="$1"

  log_info "Searching for: \"$query\""
  log_debug "Search path: $SEARCH_PATH"

  # Build commands
  local rg_cmd
  rg_cmd=$(build_rg_command "$query")

  local fzf_cmd
  fzf_cmd=$(build_fzf_command)

  log_debug "ripgrep command: $rg_cmd"
  log_debug "fzf command: $fzf_cmd"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would execute:"
    log_warning "  $rg_cmd | $fzf_cmd | awk -F: '{print \"+\"\$2\" \"\$1}' | xargs -r $EDITOR_CMD -g"
    return 0
  fi

  # Execute the search pipeline
  local selected_result
  if ! selected_result=$(eval "$rg_cmd" | eval "$fzf_cmd"); then
    if [[ $? -eq 130 ]]; then
      log_info "Search cancelled by user"
      return 0
    else
      log_error "Search failed or no results found"
      return 1
    fi
  fi

  if [[ -z "$selected_result" ]]; then
    log_warning "No file selected"
    return 0
  fi

  # Parse the selected result and open in editor
  local file_and_line
  file_and_line=$(echo "$selected_result" | awk -F: '{print "+"$2" "$1}')

  log_info "Opening: $file_and_line"
  log_debug "Editor command: $EDITOR_CMD -g $file_and_line"

  if ! eval "$EDITOR_CMD -g $file_and_line"; then
    log_error "Failed to open file in editor: $EDITOR_CMD"
    return 1
  fi

  log_success "File opened successfully in $EDITOR_CMD"
}

parse_arguments() {
  local search_query=""

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
      -p|--path)
        if [[ -z "${2:-}" ]]; then
          log_error "--path requires a directory argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        SEARCH_PATH="$2"
        shift 2
        ;;
      -e|--editor)
        if [[ -z "${2:-}" ]]; then
          log_error "--editor requires a command argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        EDITOR_CMD="$2"
        shift 2
        ;;
      -l|--lines)
        if [[ -z "${2:-}" ]]; then
          log_error "--lines requires a numeric argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        PREVIEW_LINES="$2"
        shift 2
        ;;
      -t|--type)
        if [[ -z "${2:-}" ]]; then
          log_error "--type requires file type(s)"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        FILE_TYPES="$2"
        shift 2
        ;;
      -x|--exclude)
        if [[ -z "${2:-}" ]]; then
          log_error "--exclude requires pattern(s)"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        EXCLUDE_PATTERNS="$2"
        shift 2
        ;;
      --case-sensitive)
        CASE_SENSITIVE="true"
        shift
        ;;
      --no-hidden)
        SEARCH_HIDDEN="false"
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
        if [[ -z "$search_query" ]]; then
          search_query="$1"
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
    if [[ -z "$search_query" ]]; then
      search_query="$1"
    else
      log_error "Too many arguments: $1"
      show_usage
      exit $EXIT_USAGE_ERROR
    fi
    shift
  done

  if [[ -z "$search_query" ]]; then
    log_error "Search query is required"
    show_usage
    exit $EXIT_USAGE_ERROR
  fi

  # Validate numeric arguments
  if ! [[ "$PREVIEW_LINES" =~ ^[0-9]+$ ]] || [[ "$PREVIEW_LINES" -lt 1 ]]; then
    log_fatal "Preview lines must be a positive integer: $PREVIEW_LINES"
  fi

  # Export for use in other functions
  export SEARCH_QUERY="$search_query"

  log_debug "Arguments parsed:"
  log_debug "  SEARCH_QUERY=$SEARCH_QUERY"
  log_debug "  SEARCH_PATH=$SEARCH_PATH"
  log_debug "  EDITOR_CMD=$EDITOR_CMD"
  log_debug "  PREVIEW_LINES=$PREVIEW_LINES"
  log_debug "  FILE_TYPES=$FILE_TYPES"
  log_debug "  EXCLUDE_PATTERNS=$EXCLUDE_PATTERNS"
  log_debug "  CASE_SENSITIVE=$CASE_SENSITIVE"
  log_debug "  SEARCH_HIDDEN=$SEARCH_HIDDEN"
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

  # Check dependencies and validate paths
  check_dependencies
  validate_search_path "$SEARCH_PATH"

  # Execute the search
  execute_search "$SEARCH_QUERY"

  if [[ "$DRY_RUN" == true ]]; then
    log_success "Dry-run completed! 🎉"
  else
    log_success "Search completed! 🎉"
  fi
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
