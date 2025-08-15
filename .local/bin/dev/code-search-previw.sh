#!/usr/bin/env bash


rg --line-number --hidden -S "${1:?query}" \
    | fzf --delimiter : --nth 3.. --preview 'bat --style=numbers --color=always {1} --line-range {2}:+' \
    | awk -F: '{print "+"$2" "$1}' | xargs -r ${EDITOR:-code} -g
