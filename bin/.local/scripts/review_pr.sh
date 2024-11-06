#!/bin/bash

# Usage: ./review_pr.sh <PULL-REQUEST-ID>
PULL_REQUEST_ID=$1
GITHUB_REPO="department-of-veterans-affairs/vets-api"
OPENAI_API_KEY=$OPENAI_API_KEY

# Fetch the PR diff using GitHub CLI
echo "Fetching PR diff..."
DIFF=$(gh pr diff "$PULL_REQUEST_ID")

# Check if fetching the diff was successful
if [ -z "$DIFF" ]; then
  echo "Failed to retrieve PR diff."
  exit 1
fi

# Read the prompt template and inject the diff, escaping special characters
PROMPT_TEMPLATE=$(<~/dotfiles/zsh/prompts/review_pr.md)
PROMPT=$(echo "${PROMPT_TEMPLATE//\$DIFF/$DIFF}" | jq -Rs .) # Escape and wrap in JSON string

# Send the prompt to OpenAI's API
echo "Sending diff to OpenAI for analysis..."
RESPONSE=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
        \"model\": \"gpt-4o-mini\",
        \"messages\": [{\"role\": \"user\", \"content\": $PROMPT}],
        \"max_tokens\": 800,
        \"temperature\": 0.2
      }")

# Check if RESPONSE is empty or null
if [[ -z "$RESPONSE" || "$RESPONSE" == "null" ]]; then
  echo "Received an empty or null response from OpenAI."
  echo "Response details: $RESPONSE"
  exit 1
fi

# Parse the response and extract the completion text
FEEDBACK=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Output the feedback
if [[ -n "$FEEDBACK" && "$FEEDBACK" != "null" ]]; then
  echo -e "$FEEDBACK"
else
  echo "Failed to parse feedback. Full response: $RESPONSE"
fi
