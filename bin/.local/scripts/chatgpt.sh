#!/usr/bin/env bash

set -euo pipefail

# ----------------------------#
# Constants & Default Values  #
# ----------------------------#

# Default Arguments
PROMPT_INPUT="${1:-}"
MODEL_TYPE="${2:-mini}"
OPENAI_API_KEY="${OPENAI_API_KEY}"

# OpenAI API Configuration based on model type
case "$MODEL_TYPE" in
  "mini")
    OPENAI_MODEL="gpt-4o-mini"
    MAX_TOKENS=8000
    TEMPERATURE=0.3
    ;;
  "standard")
    OPENAI_MODEL="gpt-4o"
    MAX_TOKENS=4000
    TEMPERATURE=0.2
    ;;
  "reasoning")
    OPENAI_MODEL="o1-mini"
    MAX_TOKENS=6000
    TEMPERATURE=0.0
    ;;
  *)
    echo "❌ Error: Invalid model type '$MODEL_TYPE'. Use: mini, standard, or reasoning"
    exit 1
    ;;
esac

readonly SCRIPT_NAME="$(basename "$0")"

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  cat << EOF
Usage: $SCRIPT_NAME <prompt|file> [model-type]

Arguments:
  <prompt|file>     Text prompt or path to file containing prompt
  [model-type]      Model to use: mini (default), standard, reasoning

Options:
  -h, --help       Show this help message
  -i, --interactive Start interactive mode
  -s, --stdin      Read prompt from stdin

Examples:
  $SCRIPT_NAME "What is the capital of France?"
  $SCRIPT_NAME ~/prompts/code-review.md standard
  $SCRIPT_NAME --interactive
  echo "Explain this code" | $SCRIPT_NAME --stdin
EOF
}

log_info() {
  echo "ℹ️  $*" >&2
}

log_success() {
  echo "✅ $*" >&2
}

log_error() {
  echo "❌ Error: $*" >&2
}

log_warning() {
  echo "⚠️  Warning: $*" >&2
}

# ----------------------------#
# Validation Functions        #
# ----------------------------#

validate_dependencies() {
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is not installed"
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_error "curl is not installed"
    exit 1
  fi

  if [[ -z "$OPENAI_API_KEY" ]]; then
    log_error "OPENAI_API_KEY environment variable is not set"
    exit 1
  fi
}

# ----------------------------#
# Input Processing Functions  #
# ----------------------------#

get_prompt_content() {
  local input="$1"

  # Check if it's a file path
  if [[ -f "$input" ]]; then
    if [[ ! -r "$input" ]]; then
      log_error "Cannot read file: $input"
      exit 1
    fi
    log_info "Reading prompt from file: $input"
    cat "$input"
  else
    # Treat as direct prompt text
    echo "$input"
  fi
}

read_stdin_prompt() {
  if [[ -t 0 ]]; then
    log_error "No input provided via stdin"
    exit 1
  fi

  log_info "Reading prompt from stdin..."
  cat
}

start_interactive_mode() {
  echo "🤖 ChatGPT Interactive Mode (Model: $OPENAI_MODEL)"
  echo "Type 'quit', 'exit', or press Ctrl+C to exit"
  echo "Type 'help' for commands"
  echo "---"

  while true; do
    echo -n "💬 You: "
    read -r user_input

    case "$user_input" in
      "quit"|"exit")
        echo "👋 Goodbye!"
        break
        ;;
      "help")
        echo "Commands:"
        echo "  quit/exit - Exit interactive mode"
        echo "  help      - Show this help"
        echo "  model     - Show current model"
        echo "  clear     - Clear screen"
        ;;
      "model")
        echo "Current model: $OPENAI_MODEL"
        ;;
      "clear")
        clear
        ;;
      "")
        continue
        ;;
      *)
        process_prompt "$user_input"
        echo ""
        ;;
    esac
  done
}

# ----------------------------#
# OpenAI API Functions        #
# ----------------------------#

send_chat_request() {
  local prompt="$1"
  local escaped_prompt

  # Escape prompt for JSON
  escaped_prompt=$(echo "$prompt" | jq -Rs .)

  log_info "Sending request to OpenAI (Model: $OPENAI_MODEL)..."

  curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
          \"model\": \"$OPENAI_MODEL\",
          \"messages\": [{\"role\": \"user\", \"content\": $escaped_prompt}],
          \"max_tokens\": $MAX_TOKENS,
          \"temperature\": $TEMPERATURE
        }"
}

validate_api_response() {
  local response="$1"

  if [[ -z "$response" || "$response" == "null" ]]; then
    log_error "Received empty or null response from OpenAI"
    exit 1
  fi

  # Check for API errors
  local error
  error=$(echo "$response" | jq -r '.error.message // empty')

  if [[ -n "$error" ]]; then
    log_error "OpenAI API error: $error"
    exit 1
  fi

  # Check if response was truncated
  local finish_reason
  finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason // empty')

  if [[ "$finish_reason" == "length" ]]; then
    log_warning "Response was truncated due to token limit"
  fi
}

extract_response_content() {
  local response="$1"
  local content

  content=$(echo "$response" | jq -r '.choices[0].message.content // empty')

  if [[ -z "$content" || "$content" == "null" ]]; then
    log_error "Failed to parse response content"
    exit 1
  fi

  echo "$content"
}

# ----------------------------#
# Output Functions            #
# ----------------------------#

display_response() {
  local content="$1"

  echo ""
  echo "🤖 ChatGPT Response:"
  echo "==================="

  # Try different markdown renderers in order of preference
  if command -v glow >/dev/null 2>&1; then
    echo "$content" | glow -
  elif command -v mdcat >/dev/null 2>&1; then
    echo "$content" | mdcat
  elif command -v bat >/dev/null 2>&1; then
    echo "$content" | bat --language=markdown --style=plain --paging=never
  else
    # Fallback to plain text with basic formatting
    echo "$content"
  fi
}

# ----------------------------#
# Core Processing Functions   #
# ----------------------------#

process_prompt() {
  local prompt="$1"

  # Send request to OpenAI
  local response
  response=$(send_chat_request "$prompt")

  # Validate and extract response
  validate_api_response "$response"
  local content
  content=$(extract_response_content "$response")

  # Display response
  display_response "$content"
}

# ----------------------------#
# Argument Parsing            #
# ----------------------------#

parse_arguments() {
  case "${1:-}" in
    -h|--help)
      show_usage
      exit 0
      ;;
    -i|--interactive)
      return 1  # Signal interactive mode
      ;;
    -s|--stdin)
      return 2  # Signal stdin mode
      ;;
    "")
      log_error "No prompt provided"
      show_usage
      exit 1
      ;;
    *)
      return 0  # Normal mode with prompt
      ;;
  esac
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Validate dependencies first
  validate_dependencies

  # Parse arguments and determine mode
  if parse_arguments "$@"; then
    # Normal mode - process single prompt
    local prompt_content
    prompt_content=$(get_prompt_content "$PROMPT_INPUT")
    process_prompt "$prompt_content"
  else
    case $? in
      1)
        # Interactive mode
        start_interactive_mode
        ;;
      2)
        # Stdin mode
        local stdin_content
        stdin_content=$(read_stdin_prompt)
        process_prompt "$stdin_content"
        ;;
    esac
  fi
}

# ----------------------------#
# Script Execution            #
# ----------------------------#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
