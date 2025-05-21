#!/usr/bin/env zsh

# Make sure asdf is initialized
if [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
    . /opt/homebrew/opt/asdf/libexec/asdf.sh
elif [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    . "$HOME/.asdf/asdf.sh"
fi

# Ensure we're using asdf Ruby
if ! command -v ruby >/dev/null || [[ "$(which ruby)" != *asdf* ]]; then
    echo "⚠️  Ruby is not set up via asdf yet. Skipping Ruby-related setup."
    return
fi

# Ensure Bundler is installed
if ! gem list -i bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

# Install global bundle
if [[ -f "$HOME/Gemfile.global" ]]; then
    echo "Installing global bundle..."
    BUNDLE_GEMFILE="$HOME/Gemfile.global" bundle install
fi

# Install toolbox dependencies if present
TOOLBOX="$PERSONAL_REPOS/jacobs_toolbox"
if [[ -d "$TOOLBOX" && -f "$TOOLBOX/Gemfile" ]]; then
    echo "Installing toolbox dependencies..."
    cd "$TOOLBOX"
    BUNDLE_GEMFILE="$TOOLBOX/Gemfile" bundle install
    cd - >/dev/null
fi

export RUBY=$(asdf which ruby)
