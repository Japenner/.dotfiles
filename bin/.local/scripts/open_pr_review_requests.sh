#!/bin/bash

# Function to open URLs in Chrome (or the default browser)
open_urls_in_browser() {
  first_url="$1"
  shift
  other_urls=("$@")

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use 'open' with Google Chrome
    open -na "Google Chrome" --args --new-window "$first_url"
    for url in "${other_urls[@]}"; do
      open -na "Google Chrome" --args "$url"
    done
  else
    # Linux: Use 'xdg-open' or 'google-chrome' directly
    google-chrome --new-window "$first_url" || xdg-open "$first_url"
    for url in "${other_urls[@]}"; do
      google-chrome "$url" || xdg-open "$url"
    done
  fi
}

# Fetch PRs requested for review and filter out drafts
urls=($(gh search prs --review-requested=@me --state=open --archived=false --json url,isDraft --limit=100 |
  jq -r '.[] | select(.isDraft == false) | .url'))

# Check if there are any URLs
if [[ ${#urls[@]} -gt 0 ]]; then
  # Open the URLs in the browser
  open_urls_in_browser "${urls[@]}"
else
  echo "No open, non-draft PRs found."
fi
