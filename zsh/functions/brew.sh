#!/usr/bin/env bash

check_non_homebrew_apps() {
  # Step 1: List all installed applications in /Applications (remove ".app" suffix)
  # Use a while-read loop to handle names with spaces correctly
  all_apps=()
  while IFS= read -r app; do
    all_apps+=("${app%.app}")
  done < <(ls /Applications)

  # Step 2: List all applications installed via Homebrew Cask (remove ".app" suffix)
  homebrew_apps=$(brew list --cask 2>/dev/null | sed 's/\.app$//')

  # Step 3: Find non-Homebrew applications
  non_homebrew_apps=()
  for app in "${all_apps[@]}"; do
    if ! echo "$homebrew_apps" | grep -q "^$app$"; then
      non_homebrew_apps+=("$app")
    fi
  done

  # Step 4: Check if each non-Homebrew application is available on Homebrew
  echo "Checking availability on Homebrew for applications not installed via Homebrew..."

  # Calculate total number of non-Homebrew applications for percentage calculation
  total_apps=${#non_homebrew_apps[@]}
  brew_available_apps=()
  brew_unavailable_apps=()
  for ((i = 0; i < total_apps; i++)); do
    app="${non_homebrew_apps[$i]}"

    # Calculate and display the completion percentage
    percentage=$(((i + 1) * 100 / total_apps))
    echo "Checking $app... ($percentage% complete)"

    if brew search --cask "^$app$" >/dev/null; then
      brew_available_apps+=("$app")
    else
      brew_unavailable_apps+=("$app")
    fi
  done

  # Output results
  echo "-----------------------------------"
  echo ""
  echo "Available on Homebrew:"
  for app in "${brew_available_apps[@]}"; do
    echo "$app"
  done
  echo ""
  echo "-----------------------------------"
  echo ""
  echo "Unavailable on Homebrew:"
  for app in "${brew_unavailable_apps[@]}"; do
    echo "$app"
  done
}

# TODO: UNTESTED!!!
reinstall_apps_with_homebrew() {
  # List of apps to reinstall with Homebrew
  local apps=("1Password" "Alfred 4" "Docker" "Firefox" "Google Chrome" "Google Drive" "Keka" "Keybase" "Notion" "Obsidian" "Postman" "Slack" "The Unarchiver" "Visual Studio Code" "Warp" "iTerm")

  # Backup directory
  local backup_dir="$HOME/app_backups"
  mkdir -p "$backup_dir"

  # Function to backup app configurations
  backup_config() {
    local app_name="$1"
    local config_paths=(
      "$HOME/Library/Application Support/$app_name"
      "$HOME/Library/Preferences/com.$(echo "$app_name" | tr ' ' '').plist"
    )

    echo "Backing up configuration for $app_name..."
    for config_path in "${config_paths[@]}"; do
      if [ -e "$config_path" ]; then
        cp -r "$config_path" "$backup_dir"
        echo "Backed up $config_path"
      else
        echo "No configuration found at $config_path"
      fi
    done
  }

  # Function to restore app configurations
  restore_config() {
    local app_name="$1"
    echo "Restoring configuration for $app_name..."
    cp -r "$backup_dir/$(basename "$app_name")" "$HOME/Library/Application Support/"
  }

  # Process each app
  for app in "${apps[@]}"; do
    echo "Processing $app..."

    # Backup configurations
    backup_config "$app"

    # Uninstall the app
    echo "Uninstalling $app from /Applications..."
    rm -rf "/Applications/$app.app"

    # Reinstall the app with Homebrew
    echo "Reinstalling $app with Homebrew..."
    brew install --cask "$(echo "$app" | tr ' ' '-')" || {
      echo "Failed to install $app with Homebrew."
      continue
    }

    # Restore configurations
    restore_config "$app"
    echo "$app has been reinstalled and configurations restored."
  done

  echo "All specified apps have been processed."
}

# Generate a new Brewfile backup with a unique timestamp
generate_brewfile_backup() {
  local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  local HOMEBREW_DIR="$DOTFILES/homebrew/Brewfile_backup_$TIMESTAMP"

  echo "🍺 Creating Homebrew backup..."

  if command -v brew >/dev/null; then
    brew bundle dump --file="$HOMEBREW_DIR/Brewfile" --force

    # Create timestamped backup
    cp "$HOMEBREW_DIR/Brewfile" "$HOMEBREW_DIR/Brewfile_backup_$TIMESTAMP"

    echo "✅ Brewfile backed up to: Brewfile_backup_$TIMESTAMP"
    echo "📍 Main Brewfile updated at: $HOMEBREW_DIR/Brewfile"
  else
    echo "Homebrew is not installed. Cannot create Brewfile backup."
  fi
}
