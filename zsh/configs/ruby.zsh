# ============================================
# Ruby Configuration (Optimized)
# ============================================

# Lazy load asdf if not already loaded
if ! command -v asdf >/dev/null 2>&1; then
  asdf() {
    unfunction asdf
    if [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
      . /opt/homebrew/opt/asdf/libexec/asdf.sh
    elif [[ -f "$HOME/.asdf/asdf.sh" ]]; then
      . "$HOME/.asdf/asdf.sh"
    fi
    asdf "$@"
  }
fi

# Only proceed if Ruby is available via asdf
check_ruby_setup() {
  # First try to use asdf to check Ruby
  if command -v asdf >/dev/null 2>&1; then
    local ruby_path=$(asdf which ruby 2>/dev/null)
    [[ -n "$ruby_path" ]] && return 0
  fi

  # Fallback: check if ruby command exists and is from asdf
  if command -v ruby >/dev/null 2>&1 && [[ "$(which ruby)" == *asdf* ]]; then
    return 0
  fi

  return 1
}

# Only set up Ruby if it's properly configured
if check_ruby_setup; then
  # Ensure Bundler is installed
  if ! gem list -i bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
  fi

  # Function to check if bundle install is needed
  bundle_install_needed() {
    local gemfile="$1"
    [[ ! -f "$gemfile" ]] && return 1
    BUNDLE_GEMFILE="$gemfile" bundle check --quiet >/dev/null 2>&1
    return $?
  }

  # Install global bundle only if needed
  if [[ -f "$HOME/Gemfile.global" ]] && bundle_install_needed "$HOME/Gemfile.global"; then
    echo "Installing global bundle..."
    BUNDLE_GEMFILE="$HOME/Gemfile.global" bundle install
  fi

  # Install toolbox dependencies if present and needed
  TOOLBOX="$PERSONAL_REPOS/jacobs_toolbox"
  if [[ -d "$TOOLBOX" && -f "$TOOLBOX/Gemfile" ]] && bundle_install_needed "$TOOLBOX/Gemfile"; then
    echo "Installing toolbox dependencies..."
    cd "$TOOLBOX"
    bundle install
    cd - >/dev/null
  fi

  # Set Ruby executable path
  if command -v asdf >/dev/null 2>&1; then
    export RUBY=$(asdf which ruby 2>/dev/null)
  fi
else
  echo "⚠️  Ruby is not set up via asdf yet. Skipping Ruby-related setup."
fi
