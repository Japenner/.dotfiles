#!/usr/bin/env zsh

# Ensure Bundler is installed
if ! gem list -i bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

BUNDLE_GEMFILE=~/Gemfile.global bundle install
