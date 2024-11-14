#!/usr/bin/env bash

# Determine the appropriate open command based on OS
open_cmd="open"
command -v open >/dev/null 2>&1 || open_cmd="xdg-open"

# Get the current branch for a given path (default: current directory)
github_current_branch() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" symbolic-ref --short HEAD
}

# Get the default branch based on the remote's HEAD
github_default_branch() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

# Get the GitHub repository URL in HTTPS format, removing any custom SSH host aliases
github_project_root() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" config remote.origin.url | \
    sed -E 's|git@([^:]+):(.+)|https://\1/\2|; s|\.git$||' | \
    sed 's|github\.com-(work|personal)|github.com|'
}

# Open the GitHub compare page between the current branch and default branch in the browser
github_compare_current_branch() {
  local file_path=${1:-$(pwd)}
  local current_branch=${2:-$(github_current_branch "$file_path")}
  local project_root=$(github_project_root "$file_path")
  local default_branch=$(github_default_branch "$file_path")

  ${open_cmd} "${project_root}/compare/${default_branch}...${current_branch}?expand=1"
}

# Open the current branch's view of a specific file or directory in GitHub
github_open_current_branch() {
  local file=${1:-""}
  local file_path=${2:-$(pwd)}
  local current_branch=$(github_current_branch "$file_path")
  local project_root=$(github_project_root "$file_path")
  local git_directory=$(git -C "$file_path" rev-parse --show-prefix)

  ${open_cmd} "${project_root}/tree/${current_branch}/${git_directory}${file}"
}

# Update the current branch by rebasing it on top of the default branch
github_update_current_branch() {
  local file_path=${1:-$(pwd)}
  local default_branch=$(github_default_branch "$file_path")

  git -C "$file_path" fetch origin
  git -C "$file_path" pull origin "$default_branch" --rebase
  git -C "$file_path" push origin "$(github_current_branch "$file_path")" --force --no-verify
}

# Get the GitHub username and repository name in the format "user/repo"
github_user_repo() {
  local file_path=${1:-$(pwd)}
  git -C "$file_path" remote get-url origin | \
    sed -E 's|.*[:/]([^/]+/[^/]+)\.git$|\1|; s|.*[:/]([^/]+/[^/]+)$|\1|'
}
