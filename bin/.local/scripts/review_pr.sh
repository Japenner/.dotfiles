#!/bin/bash

set -e

# ----------------------------#
# Constants & Default Values  #
# ----------------------------#

# Default Arguments
PULL_REQUEST_ID=$1
MODEL_TYPE=${2:-"mini"}  # mini, standard, or reasoning
OPENAI_API_KEY=${OPENAI_API_KEY}

# OpenAI API Configuration based on model type
case "$MODEL_TYPE" in
  "mini")
    OPENAI_MODEL="gpt-4o-mini"
    MAX_TOKENS=5000
    TEMPERATURE=0.2
    ;;
  "standard")
    OPENAI_MODEL="gpt-4o"
    MAX_TOKENS=3000
    TEMPERATURE=0.1  # Even more focused for thorough analysis
    ;;
  "reasoning")
    OPENAI_MODEL="o1-mini"
    MAX_TOKENS=4000
    TEMPERATURE=0.0  # o1 models work best with minimal randomness
    ;;
esac

# File Paths
PROMPT_TEMPLATE_PATH="$HOME/.dotfiles/prompts/review_pr.md"

# Dynamic Variables (set by functions)
GITHUB_REPO=""

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  echo "Usage: $(basename "$0") <pull-request-id> [model-type]"
  echo "  pull-request-id    The GitHub PR number to review"
  echo "  model-type         Model to use: mini (default), standard, reasoning"
  echo ""
  echo "Fetches a PR diff from the current repository and sends it to OpenAI for automated code review feedback"
}

validate_arguments() {
  if [[ -z "$PULL_REQUEST_ID" ]]; then
    echo "❌ Error: Pull request ID is required"
    show_usage
    exit 1
  fi

  if [[ "$PULL_REQUEST_ID" == "--help" || "$PULL_REQUEST_ID" == "-h" ]]; then
    show_usage
    exit 0
  fi
}

validate_git_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Error: Not inside a Git repository"
    exit 1
  fi
}

validate_dependencies() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ Error: jq is not installed"
    exit 1
  fi

  if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "❌ Error: OPENAI_API_KEY environment variable is not set"
    exit 1
  fi

  if [[ ! -f "$PROMPT_TEMPLATE_PATH" ]]; then
    echo "❌ Error: Prompt template not found at $PROMPT_TEMPLATE_PATH"
    exit 1
  fi
}

# ----------------------------#
# Repository Functions        #
# ----------------------------#

get_github_repository() {
  echo "🔍 Detecting GitHub repository..."

  local remote_url
  remote_url=$(git config --get remote.origin.url)

  if [[ -z "$remote_url" ]]; then
    echo "❌ Error: No origin remote found"
    exit 1
  fi

  # Convert SSH/HTTPS URLs to owner/repo format
  local repo
  if [[ "$remote_url" =~ git@github\.com:([^/]+)/(.+)\.git$ ]]; then
    # SSH format: git@github.com:owner/repo.git
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/(.+)\.git$ ]]; then
    # HTTPS format: https://github.com/owner/repo.git
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ github\.com[:/]([^/]+)/(.+)$ ]]; then
    # Generic format without .git suffix
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
  else
    echo "❌ Error: Could not parse GitHub repository from remote URL: $remote_url"
    exit 1
  fi

  GITHUB_REPO="$repo"
  echo "📁 Using repository: $GITHUB_REPO"
}

# ----------------------------#
# PR Fetching Functions       #
# ----------------------------#

fetch_pr_diff() {
  echo "🔍 Fetching PR diff for #$PULL_REQUEST_ID from $GITHUB_REPO..."

  local diff
  diff=$(gh pr diff "$PULL_REQUEST_ID" --repo "$GITHUB_REPO")

  if [[ -z "$diff" ]]; then
    echo "❌ Error: Failed to retrieve PR diff"
    exit 1
  fi

  echo "$diff"
}

# ----------------------------#
# Prompt Generation Functions #
# ----------------------------#

load_prompt_template() {
  if [[ ! -r "$PROMPT_TEMPLATE_PATH" ]]; then
    echo "❌ Error: Cannot read prompt template at $PROMPT_TEMPLATE_PATH"
    exit 1
  fi

  cat "$PROMPT_TEMPLATE_PATH"
}

generate_review_prompt() {
  local diff="$1"
  local template

  template=$(load_prompt_template)

  # Replace $DIFF placeholder with actual diff content and escape for JSON
  echo "${template//\$DIFF/$diff}" | jq -Rs .
}

# ----------------------------#
# OpenAI API Functions        #
# ----------------------------#

send_review_request() {
  local prompt="$1"

  echo "🤖 Sending diff to OpenAI for analysis..." >&2

  curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
          \"model\": \"$OPENAI_MODEL\",
          \"messages\": [{\"role\": \"user\", \"content\": $prompt}],
          \"max_tokens\": $MAX_TOKENS,
          \"temperature\": $TEMPERATURE
        }"
}

validate_api_response() {
  local response="$1"

  if [[ -z "$response" || "$response" == "null" ]]; then
    echo "❌ Error: Received empty or null response from OpenAI"
    echo "Response details: $response"
    exit 1
  fi

  # Check for API errors
  local error
  error=$(echo "$response" | jq -r '.error.message // empty')

  if [[ -n "$error" ]]; then
    echo "❌ Error: OpenAI API returned an error: $error"
    exit 1
  fi

  # Check if response was truncated
  local finish_reason
  finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason // empty')

  if [[ "$finish_reason" == "length" ]]; then
    echo "⚠️  Warning: Response was truncated due to token limit. Consider increasing MAX_TOKENS." >&2
  fi
}

extract_review_feedback() {
  local response="$1"

  local feedback
  feedback=$(echo "$response" | jq -r '.choices[0].message.content // empty')

  if [[ -z "$feedback" || "$feedback" == "null" ]]; then
    echo "❌ Error: Failed to parse feedback from response"
    echo "Full response: $response"
    exit 1
  fi

  echo "$feedback"
}

# ----------------------------#
# Output Functions            #
# ----------------------------#

display_review_feedback() {
  local feedback="$1"

  echo ""
  echo "📝 AI Code Review Feedback:"
  echo "=========================="

  # Try different markdown renderers in order of preference
  if command -v glow >/dev/null 2>&1; then
    echo "$feedback" | glow -
  elif command -v mdcat >/dev/null 2>&1; then
    echo "$feedback" | mdcat
  elif command -v bat >/dev/null 2>&1; then
    echo "$feedback" | bat --language=markdown --style=plain
  elif command -v rich >/dev/null 2>&1; then
    echo "$feedback" | rich - --markdown
  else
    # Fallback to plain text
    echo -e "$feedback"
  fi
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Validate inputs and dependencies
  validate_arguments
  validate_git_repository
  get_github_repository
  validate_dependencies

  # Fetch PR diff
  local diff
  diff=$(fetch_pr_diff)

  # Generate review prompt
  local prompt
  prompt=$(generate_review_prompt "$diff")

  # Send to OpenAI and get response
  local response
  response=$(send_review_request "$prompt")

  # Validate and extract feedback
  validate_api_response "$response"
  local feedback
  feedback=$(extract_review_feedback "$response")

  # Display results
  display_review_feedback "$feedback"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
