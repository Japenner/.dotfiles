#!/bin/bash

set -e

# ----------------------------#
# Constants & Default Values  #
# ----------------------------#

# Default Arguments
MAX_PRS=${1:-100}
BROWSER="Google Chrome"

# GitHub CLI Query Parameters
SEARCH_PARAMS=(
  "--review-requested=@me"
  "--state=open"
  "--archived=false"
  "--limit=$MAX_PRS"
)

# JSON Query for filtering out drafts
JQ_FILTER='.[] | select(.isDraft == false) | .url'

# ----------------------------#
# Helper Functions            #
# ----------------------------#

show_usage() {
  echo "Usage: $(basename "$0") [max_prs]"
  echo "  max_prs    Maximum number of PRs to fetch (default: 100)"
  echo ""
  echo "Opens all non-draft PRs awaiting your review in browser tabs"
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
}

# ----------------------------#
# PR Fetching Functions       #
# ----------------------------#

fetch_pending_review_prs() {
  gh search prs "${SEARCH_PARAMS[@]}" \
    --json url,isDraft \
    | jq -r "$JQ_FILTER"
}

count_prs() {
  local urls=("$@")
  echo "${#urls[@]}"
}

# ----------------------------#
# Browser Functions           #
# ----------------------------#

open_url_in_new_window() {
  local url="$1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Open first URL in new window
    open -na "$BROWSER" --args --new-window "$url"
  else
    # Linux: Use google-chrome or fallback to xdg-open
    google-chrome --new-window "$url" 2>/dev/null || xdg-open "$url"
  fi
}

open_url_in_new_tab() {
  local url="$1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Open subsequent URLs in new tabs
    open -na "$BROWSER" --args "$url"
  else
    # Linux: Open in new tab
    google-chrome "$url" 2>/dev/null || xdg-open "$url"
  fi
}

open_prs_in_browser() {
  local urls=("$@")
  local pr_count=$(count_prs "${urls[@]}")

  if [[ $pr_count -eq 0 ]]; then
    echo "ℹ️  No PRs awaiting your review"
    return 0
  fi

  echo "🌐 Opening $pr_count PR$([ $pr_count -ne 1 ] && echo "s") in browser..."

  # Open first URL in new window
  open_url_in_new_window "${urls[0]}"

  # Open remaining URLs in new tabs
  for url in "${urls[@]:1}"; do
    open_url_in_new_tab "$url"
  done

  echo "✅ Opened $pr_count PR review$([ $pr_count -ne 1 ] && echo "s")"
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

main() {
  # Show help if requested
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_usage
    exit 0
  fi

  # Validate required tools
  validate_dependencies

  # Show status message
  echo "🔍 Fetching PRs awaiting your review..."

  # Fetch PRs awaiting review and store in temp file
  local temp_file=$(mktemp)
  fetch_pending_review_prs > "$temp_file"

  # Read URLs into array
  local pr_urls=()
  while IFS= read -r url; do
    [[ -n "$url" ]] && pr_urls+=("$url")
  done < "$temp_file"

  # Clean up temp file
  rm "$temp_file"

  # Open PRs in browser
  open_prs_in_browser "${pr_urls[@]}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
