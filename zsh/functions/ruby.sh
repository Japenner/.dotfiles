#!/usr/bin/env bash

# Open the specified gem's source code in the configured code editor
ruby_edit_gem() {
  if [[ -z "$1" ]]; then
    echo "Please provide a gem name."
    return 1
  fi

  local gem_path
  gem_path=$(bundle show "$1" 2>/dev/null)

  if [[ -n "$gem_path" ]]; then
    "$CODE_EDITOR" "$gem_path"
  else
    echo "Gem '$1' not found in the current bundle."
    return 1
  fi
}

# Fix Rubocop issues by creating a new branch, applying autofixes, committing, and pushing changes
ruby_fix_rubocop_issues() {
  local default_branch
  default_branch=$(github_default_branch 2>/dev/null)

  if [[ -z "$default_branch" ]]; then
    echo "Failed to retrieve the default branch. Ensure github_default_branch function is defined."
    return 1
  fi

  # Switch to the default branch and update it
  git checkout "$default_branch" || { echo "Failed to switch to $default_branch."; return 1; }
  git pull || { echo "Failed to pull latest changes."; return 1; }

  # Create and switch to a new branch for Rubocop fixes
  git checkout -b "jap/rubocop-fixes" || { echo "Failed to create a new branch for Rubocop fixes."; return 1; }

  # Install Ruby dependencies
  bundle install || { echo "Failed to install Ruby dependencies."; return 1; }

  # Check for JavaScript dependencies and install if present
  if [[ -f "package.json" ]]; then
    echo "JavaScript dependencies detected. Installing with yarn..."
    yarn install || { echo "Failed to install JavaScript dependencies with yarn."; return 1; }
  else
    echo "No JavaScript dependencies detected. Skipping yarn install."
  fi

  # Run Rubocop with autofix
  bundle exec rubocop -A || { echo "Rubocop failed to run."; return 1; }

  # Stage, commit, and push changes
  git add . || { echo "Failed to stage changes."; return 1; }
  git commit -m "fix: Changes to clean up Rubocop issues found" || { echo "Failed to commit changes."; return 1; }
  git push -u origin "jap/rubocop-fixes" || { echo "Failed to push branch."; return 1; }

  # Open GitHub compare page between the new branch and the default branch
  github_compare_current_branch || { echo "Failed to open GitHub compare page."; return 1; }

  # Return to the previous branch
  git checkout - || { echo "Failed to switch back to the original branch."; return 1; }
}

# Reusable function for installing Ruby and JavaScript dependencies
ruby_install_dependencies() {
  bundle install
  if [[ -f "package.json" ]]; then
    yarn install
  fi
}

# Install dependencies and start Foreman
ruby_start_foreman() {
  ruby_install_dependencies
  bin/foreman start
}

# Install dependencies and run Rubocop and RSpec
ruby_run_code_quality_checks() {
  ruby_install_dependencies
  bundle exec rubocop
  bundle exec rspec
}

# Reset the database for a given environment (default: development)
rails_reset_database() {
  local env="${1:-development}"
  RAILS_ENV="$env" bundle exec rails db:reset
}

# Run Rails migrations, rollback, and prepare test database
rails_run_migrations() {
  bundle exec rails db:migrate
  bundle exec rails db:rollback
  bundle exec rails db:migrate
  bundle exec rails db:test:prepare
}

# Install dependencies and start Rails console (default environment: development)
rails_start_console() {
  local env="${1:-development}"
  ruby_install_dependencies
  RAILS_ENV="$env" bundle exec rails c
}

# Install dependencies and start Rails server (default environment: development)
rails_start_server() {
  local env="${1:-development}"
  ruby_install_dependencies
  RAILS_ENV="$env" bundle exec rails s
}

# Run Rails tests after installing dependencies
rails_run_tests() {
  ruby_install_dependencies
  bundle exec rails test
}
