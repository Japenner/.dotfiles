#!/bin/bash

# Set statuses here
status_text="Out of Office"
status_emoji=":palm_tree:"

# Convert duration to seconds for expiry
status_duration_hours=8
status_expiration=$(($(date +%s) + status_duration_hours * 3600))

# Add tokens for each workspace
declare -A SLACK_WORKSPACES=(
  ["ad_hoc"]="$AD_HOC_WORKSPACE_TOKEN"
  # ["workspace2"]="xoxp-your-token-2"
)

# Function to set the status
set_status() {
  for workspace in "${!SLACK_WORKSPACES[@]}"; do
    curl -s -X POST -H "Authorization: Bearer ${SLACK_WORKSPACES[$workspace]}" \
      -H "Content-Type: application/json" \
      -d '{
        "profile": {
          "status_text": "'"$status_text"'",
          "status_emoji": "'"$status_emoji"'",
          "status_expiration": "'"$status_expiration"'"
        }
      }' "https://slack.com/api/users.profile.set" | jq
  done
}

# Function to clear the status
clear_status() {
  for workspace in "${!SLACK_WORKSPACES[@]}"; do
    curl -s -X POST -H "Authorization: Bearer ${SLACK_WORKSPACES[$workspace]}" \
      -H "Content-Type: application/json" \
      -d '{
        "profile": {
          "status_text": "",
          "status_emoji": "",
          "status_expiration": 0
        }
      }' "https://slack.com/api/users.profile.set" | jq
  done
}

# Check command line argument
if [ "$1" == "set" ]; then
  set_status
elif [ "$1" == "clear" ]; then
  clear_status
else
  echo "Usage: $0 {set|clear}"
fi
