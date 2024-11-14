#!/usr/bin/env zsh

# Ensure Bundler is installed
if ! gem list -i bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

BUNDLE_GEMFILE=~/Gemfile.global bundle install

# Install toolbox dependencies if the my toolbox is present
TOOLBOX=$HOME/repos/personal/jacobs_toolbox
if [ -d $TOOLBOX ]; then
    echo "Installing toolbox dependencies..."
    cd $TOOLBOX
    BUNDLE_GEMFILE=$TOOLBOX/Gemfile bundle install
fi
