#!/bin/bash

# Get the relative path from the Git repository root to the current directory
# GIT_PREFIX=$(git rev-parse --show-prefix)

# Provide credentials based on the repository path
case "$(pwd)" in
"$PERSONAL_REPOS"/*)
    echo "username=$GITHUB_USERNAME_PERSONAL"
    echo "password=$GITHUB_PAT_PERSONAL"
    ;;
"$WORK_REPOS"/va/*)
    echo "username=$GITHUB_USERNAME_WORK"
    echo "password=$GITHUB_PAT_WORK"
    ;;
*)
    echo "No matching credentials"
    ;;
esac
