#!/bin/bash

set -e

# ----------------------------#
# Constants & Default Values  #
# ----------------------------#

# Default Arguments
ISSUE_NUMBER=$1
POINTS=${2:-3}
REPOSITORY=${3:-department-of-veterans-affairs/VA.gov-team-forms}
PREFIX="jap/simple-forms/"

# GraphQL Queries
GET_CARD_ID_QUERY='query($issueNumber: Int!, $repoName: String!, $repoOwner: String!) {
  repository(name: $repoName, owner: $repoOwner) {
    issue(number: $issueNumber) {
      projectItems(first: 1) {
        nodes { id }
      }
    }
  }
}'

GET_PROJECT_QUERY='query($repoOwner: String!, $repoName: String!, $issueNumber: Int!) {
  repository(owner: $repoOwner, name: $repoName) {
    issue(number: $issueNumber) {
      projectItems(first: 1) {
        nodes {
          id
          project {
            id
            fields(first: 20) { nodes { ... on ProjectV2FieldCommon { id name } } }
          }
        }
      }
    }
  }
}'

GET_STATUS_OPTIONS_QUERY='query($statusFieldId: ID!) {
  node(id: $statusFieldId) {
    ... on ProjectV2SingleSelectField {
      options { id name }
    }
  }
}'

UPDATE_POINTS_FIELD_QUERY='mutation($projectId: ID!, $itemId: ID!, $points: Float!, $fieldId: ID!) {
  updateProjectV2ItemFieldValue(input: { projectId: $projectId, itemId: $itemId, fieldId: $fieldId, value: { number: $points } }) {
    projectV2Item { id }
  }
}'

UPDATE_STATUS_FIELD_QUERY='mutation($projectId: ID!, $itemId: ID!, $singleSelectOptionId: String, $fieldId: ID!) {
  updateProjectV2ItemFieldValue(input: { projectId: $projectId, itemId: $itemId, fieldId: $fieldId, value: { singleSelectOptionId: $singleSelectOptionId } }) {
    projectV2Item { id }
  }
}'

# ----------------------------#
# Functions                   #
# ----------------------------#

assign_issue_to_self() {
  gh issue edit "$ISSUE_NUMBER" --repo "$REPOSITORY" --add-assignee @me
}

get_issue_title() {
  gh issue view "$ISSUE_NUMBER" --repo "$REPOSITORY" --json title --jq .title
}

create_branch() {
  local issue_title=$(get_issue_title)
  local branch_name="$PREFIX$ISSUE_NUMBER-$(echo $issue_title | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/-$//')"
  git checkout -b "$branch_name"
  echo "Created new branch: $branch_name"
}

extract_repo_owner_and_name() {
  REPO_NAME=$(echo "$REPOSITORY" | cut -d '/' -f2)
  REPO_OWNER=$(echo "$REPOSITORY" | cut -d '/' -f1)
}

fetch_card_id() {
  gh api graphql -F issueNumber="$ISSUE_NUMBER" -F repoName="$REPO_NAME" -F repoOwner="$REPO_OWNER" -f query="$GET_CARD_ID_QUERY" --jq '.data.repository.issue.projectItems.nodes[0].id'
}

fetch_project_info() {
  gh api graphql -F issueNumber="$ISSUE_NUMBER" -F repoName="$REPO_NAME" -F repoOwner="$REPO_OWNER" -f query="$GET_PROJECT_QUERY" --jq '{
    projectId: .data.repository.issue.projectItems.nodes[0].project.id,
    pointsFieldId: (.data.repository.issue.projectItems.nodes[0].project.fields.nodes[] | select(.name == "Points") | .id),
    statusFieldId: (.data.repository.issue.projectItems.nodes[0].project.fields.nodes[] | select(.name == "Status") | .id)
  }'
}

update_project_card_points() {
  gh api graphql -F projectId="$PROJECT_ID" -F itemId="$CARD_ID" -F points="$POINTS" -F fieldId="$POINTS_FIELD_ID" -f query="$UPDATE_POINTS_FIELD_QUERY" > /dev/null 2>&1
}

fetch_status_options() {
  gh api graphql -F statusFieldId="$STATUS_FIELD_ID" -f query="$GET_STATUS_OPTIONS_QUERY" --jq '.data.node.options'
}

get_status_id() {
  local status_options=$(fetch_status_options)
  echo "$status_options" | jq -r '.[] | select(.name | contains("In Progress")) | .id'
}

update_project_card_status() {
  gh api graphql -F projectId="$PROJECT_ID" -F itemId="$CARD_ID" -F singleSelectOptionId="$NEW_STATUS_ID" -F fieldId="$STATUS_FIELD_ID" -f query="$UPDATE_STATUS_FIELD_QUERY" > /dev/null 2>&1
}

# ----------------------------#
# Main Execution              #
# ----------------------------#

assign_issue_to_self
create_branch
extract_repo_owner_and_name

# Fetch project details and update points & status
CARD_ID=$(fetch_card_id)
PROJECT=$(fetch_project_info)

PROJECT_ID=$(echo "$PROJECT" | jq -r '.projectId')
POINTS_FIELD_ID=$(echo "$PROJECT" | jq -r '.pointsFieldId')
STATUS_FIELD_ID=$(echo "$PROJECT" | jq -r '.statusFieldId')

NEW_STATUS_ID=$(get_status_id)

update_project_card_points
update_project_card_status

echo "Updated issue #$ISSUE_NUMBER with $POINTS points and set status to 'In Progress' in the associated GitHub project."

open -na "Google Chrome" --args "https://github.com/$REPOSITORY/issues/$ISSUE_NUMBER"
