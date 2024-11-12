#!/bin/bash

case "$GIT_PREFIX" in
    ~/Repos/personal/*)
        echo "username=japenner"
        echo "password=$GITHUB_PAT_PERSONAL"
        ;;
    ~/Repos/ad_hoc/va/*)
        echo "username=pennja"
        echo "password=$GITHUB_PAT_AD_HOC"
        ;;
    *)
        echo "No matching credentials"
        ;;
esac
