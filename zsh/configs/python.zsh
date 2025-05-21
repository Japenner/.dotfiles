#!/usr/bin/env zsh

# Make sure asdf is initialized
if [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
  . /opt/homebrew/opt/asdf/libexec/asdf.sh
elif [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  . "$HOME/.asdf/asdf.sh"
fi

# Ensure we're using asdf Ruby
if ! command -v python >/dev/null || [[ "$(which python)" != *asdf* ]]; then
  echo "⚠️  Python is not set up via asdf yet. Skipping Python-related setup."
  return
fi

export PYTHON=$(asdf which python3)
