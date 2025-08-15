#!/usr/bin/env bash

# Typer - Cross-platform text simulation tool
#
# Features:
# - Cross-platform support (Linux with xdotool, macOS with AppleScript)
# - Configurable typing delay and behavior
# - Input validation and error handling
# - Dry-run mode for testing
# - Comprehensive help and logging
#
# Usage: typer.sh [options] "<text_to_type>"

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
DEFAULT_DELAY="${TYPER_DEFAULT_DELAY:-75}"
MIN_DELAY="${TYPER_MIN_DELAY:-1}"
MAX_DELAY="${TYPER_MAX_DELAY:-5000}"
TYPING_METHOD="${TYPER_METHOD:-auto}"  # auto, xdotool, osascript

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  printf "%b\n" "${BOLD}$SCRIPT_NAME${NC} v$SCRIPT_VERSION

Cross-platform text simulation tool for automating typing tasks.

${BOLD}Usage:${NC} $SCRIPT_NAME [options] \"<text_to_type>\"

${BOLD}Arguments:${NC}
  ${BOLD}<text_to_type>${NC}         Text to simulate typing

${BOLD}Options:${NC}
  ${BOLD}-d, --delay DELAY${NC}      Delay between keystrokes in ms (default: $DEFAULT_DELAY)
  ${BOLD}-m, --method METHOD${NC}    Typing method: auto, xdotool, osascript (default: $TYPING_METHOD)
  ${BOLD}--dry-run${NC}              Show what would be typed without executing
  ${BOLD}-h, --help${NC}             Show this help message
  ${BOLD}-q, --quiet${NC}            Suppress non-error output
  ${BOLD}-v, --verbose${NC}          Enable verbose output
  ${BOLD}--version${NC}              Show version information

${BOLD}Environment Variables:${NC}
  ${BOLD}TYPER_DEFAULT_DELAY${NC}     Default delay in milliseconds (default: 75)
  ${BOLD}TYPER_MIN_DELAY${NC}         Minimum allowed delay (default: 1)
  ${BOLD}TYPER_MAX_DELAY${NC}         Maximum allowed delay (default: 5000)
  ${BOLD}TYPER_METHOD${NC}            Preferred typing method (default: auto)

${BOLD}Examples:${NC}
  $SCRIPT_NAME \"cat /dev/ttyACM3\"                    # Type with default delay
  $SCRIPT_NAME -d 100 \"ls -la\"                       # Type with 100ms delay
  $SCRIPT_NAME --method osascript \"Hello World\"      # Force macOS method
  $SCRIPT_NAME --dry-run \"test command\"              # Preview without typing

${BOLD}Supported Platforms:${NC}
  - Linux: Uses xdotool for X11 window management
  - macOS: Uses AppleScript for System Events simulation
  - Windows: Currently not supported

For more information, see: https://github.com/japenner/.dotfiles/.local/dev/typer.sh"
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

# Detect the best typing method for the current platform
detect_typing_method() {
  case "$(uname -s)" in
    Linux*)
      if command_exists xdotool; then
        echo "xdotool"
      else
        log_fatal "xdotool not found. Install with: sudo apt-get install xdotool (Ubuntu/Debian) or equivalent"
      fi
      ;;
    Darwin*)
      if command_exists osascript; then
        echo "osascript"
      else
        log_fatal "osascript not found. This should be available on all macOS systems."
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      log_fatal "Windows platform not currently supported"
      ;;
    *)
      log_fatal "Unsupported platform: $(uname -s)"
      ;;
  esac
}

# Validate typing method
validate_typing_method() {
  local method="$1"

  case "$method" in
    auto)
      detect_typing_method
      ;;
    xdotool)
      if ! command_exists xdotool; then
        log_fatal "xdotool not found but explicitly requested"
      fi
      echo "xdotool"
      ;;
    osascript)
      if ! command_exists osascript; then
        log_fatal "osascript not found but explicitly requested (macOS only)"
      fi
      echo "osascript"
      ;;
    *)
      log_fatal "Invalid typing method: $method. Supported: auto, xdotool, osascript"
      ;;
  esac
}

# Validate delay parameter
validate_delay() {
  local delay="$1"

  # Check if it's a number
  if ! [[ "$delay" =~ ^[0-9]+$ ]]; then
    log_fatal "Delay must be a positive integer: $delay"
  fi

  # Check bounds
  if [[ $delay -lt $MIN_DELAY ]]; then
    log_fatal "Delay too small: $delay (minimum: $MIN_DELAY)"
  fi

  if [[ $delay -gt $MAX_DELAY ]]; then
    log_fatal "Delay too large: $delay (maximum: $MAX_DELAY)"
  fi

  log_debug "Validated delay: ${delay}ms"
}

# Escape text for different typing methods
escape_text() {
  local text="$1"
  local method="$2"

  case "$method" in
    xdotool)
      # xdotool handles most characters well, but we should escape some special ones
      echo "$text"
      ;;
    osascript)
      # AppleScript requires escaping quotes and backslashes
      text="${text//\\/\\\\}"  # Escape backslashes first
      text="${text//\"/\\\"}"  # Escape quotes
      echo "$text"
      ;;
    *)
      echo "$text"
      ;;
  esac
}

# Type text using xdotool (Linux)
type_with_xdotool() {
  local text="$1"
  local delay="$2"

  log_info "Typing with xdotool (delay: ${delay}ms)"
  log_debug "Command: xdotool type --delay $delay \"$text\""

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would execute: xdotool type --delay $delay \"$text\""
    return 0
  fi

  if ! xdotool type --delay "$delay" "$text"; then
    log_fatal "xdotool command failed"
  fi
}

# Type text using AppleScript (macOS)
type_with_osascript() {
  local text="$1"
  local delay="$2"

  # Convert milliseconds to seconds for AppleScript
  local delay_seconds
  delay_seconds=$(awk "BEGIN {printf \"%.3f\", $delay/1000}")

  log_info "Typing with AppleScript (delay: ${delay}ms)"
  log_debug "Delay in seconds: $delay_seconds"

  local escaped_text
  escaped_text=$(escape_text "$text" "osascript")

  # Build AppleScript command
  local applescript="
    tell application \"System Events\"
      repeat with char in every character of \"$escaped_text\"
        keystroke char
        delay $delay_seconds
      end repeat
    end tell
  "

  log_debug "AppleScript: $applescript"

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "[DRY RUN] Would execute AppleScript to type: \"$text\""
    log_warning "[DRY RUN] Character delay: ${delay_seconds}s"
    return 0
  fi

  if ! osascript -e "$applescript"; then
    log_fatal "AppleScript command failed"
  fi
}

# Main typing function
type_text() {
  local text="$1"
  local delay="$2"
  local method="$3"

  # Truncate text for display if it's too long
  local display_text="$text"
  if [[ ${#text} -gt 50 ]]; then
    display_text="${text:0:50}..."
  fi

  log_info "Typing text: \"$display_text\""
  log_debug "Method: $method, Delay: ${delay}ms"

  case "$method" in
    xdotool)
      type_with_xdotool "$text" "$delay"
      ;;
    osascript)
      type_with_osascript "$text" "$delay"
      ;;
    *)
      log_fatal "Unknown typing method: $method"
      ;;
  esac
}

parse_arguments() {
  local text_to_type=""
  local delay="$DEFAULT_DELAY"
  local method="$TYPING_METHOD"

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
      -d|--delay)
        if [[ -z "${2:-}" ]]; then
          log_error "--delay requires a numeric argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        delay="$2"
        shift 2
        ;;
      -m|--method)
        if [[ -z "${2:-}" ]]; then
          log_error "--method requires an argument"
          show_usage
          exit $EXIT_USAGE_ERROR
        fi
        method="$2"
        shift 2
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
        if [[ -z "$text_to_type" ]]; then
          text_to_type="$1"
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
    if [[ -z "$text_to_type" ]]; then
      text_to_type="$1"
    else
      log_error "Too many arguments: $1"
      show_usage
      exit $EXIT_USAGE_ERROR
    fi
    shift
  done

  if [[ -z "$text_to_type" ]]; then
    log_error "Text to type is required"
    show_usage
    exit $EXIT_USAGE_ERROR
  fi

  # Validate parameters
  validate_delay "$delay"
  method=$(validate_typing_method "$method")

  # Export for use in other functions
  export TEXT_TO_TYPE="$text_to_type"
  export TYPING_DELAY="$delay"
  export TYPING_METHOD="$method"

  log_debug "Arguments parsed:"
  log_debug "  TEXT_TO_TYPE=$TEXT_TO_TYPE"
  log_debug "  TYPING_DELAY=$TYPING_DELAY"
  log_debug "  TYPING_METHOD=$TYPING_METHOD"
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
  log_debug "Platform: $(uname -s)"

  # Type the text
  type_text "$TEXT_TO_TYPE" "$TYPING_DELAY" "$TYPING_METHOD"

  if [[ "$DRY_RUN" == true ]]; then
    log_success "Dry-run completed! 🎉"
  else
    log_success "Text typed successfully! 🎉"
  fi
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
