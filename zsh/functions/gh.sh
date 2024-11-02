# Dynamically set the default branch based on the remote's HEAD
get_default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

fix_issues() {
  git stash
  default_branch=$(get_default_branch)
  git checkout "$default_branch"
  git pull
  git checkout -b jap/rubocop-fixes
  yarn install
  bundle install
  rubocop -A
  git add .
  git commit -m "fix: Changes to clean up Rubocop issues found"
  git push
  gh-c
}

# Use `xdg-open` if `open` command is not available
open_cmd="open"
command -v open >/dev/null 2>&1 || open_cmd="xdg-open"

# Open current branch in browser on GitHub
gh-b() {
  local file=${1:-""}
  local git_branch=${2:-$(git symbolic-ref --quiet --short HEAD)}
  local git_project_root=$(git config remote.origin.url | sed "s~git@\(.*\):\(.*\)~https://\1/\2~" | sed "s~\(.*\).git\$~\1~")
  local git_directory=$(git rev-parse --show-prefix)
  ${open_cmd} "${git_project_root}/tree/${git_branch}/${git_directory}${file}"
}

# Open GitHub compare page between current branch and default branch in browser
gh-c() {
  local git_branch=${2:-$(git symbolic-ref --quiet --short HEAD)}
  local git_project_root=$(git config remote.origin.url | sed "s~git@\(.*\):\(.*\)~https://\1/\2~" | sed "s~\(.*\).git\$~\1~")
  local default_branch=$(get_default_branch)
  ${open_cmd} "${git_project_root}/compare/${default_branch}...${git_branch}?expand=1"
}
