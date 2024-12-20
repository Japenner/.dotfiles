#!/usr/bin/env zsh

# Ensure Bundler is installed
if ! gem list -i bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

BUNDLE_GEMFILE=$HOME/Gemfile.global bundle install

# Install toolbox dependencies if my toolbox is present
TOOLBOX=$PERSONAL_REPOS/jacobs_toolbox
# if [ -d $TOOLBOX ]; then
#     echo "Installing toolbox dependencies..."
#     cd $TOOLBOX
#     BUNDLE_GEMFILE=$TOOLBOX/Gemfile bundle install
# fi
