#!/usr/bin/env bash

# This script provides a tmux-based interface to access cheat sheets from cht.sh,
# allowing users to search by programming language or command. It uses fzf for
# selection, prompts for a query, and opens a new tmux window to display the
# results from cht.sh.

# Use `fzf` to allow the user to select an item from two files:
# `~/.tmux-cht-languages` and `~/.tmux-cht-command`.
# `selected` will hold the user's choice or be empty if nothing is selected.
selected=`cat ~/.tmux-cht-languages ~/.tmux-cht-command | fzf`

if [[ -z $selected ]]; then
    exit 0
fi

read -p "Enter Query: " query

# Check if the selected item exists in the file `~/.tmux-cht-languages`.
if grep -qs "$selected" ~/.tmux-cht-languages; then
    # If the selected item is found in `~/.tmux-cht-languages`, format the query for a language search:
    # Replace spaces with plus signs in the `query` to make it URL-friendly.
    query=`echo $query | tr ' ' '+'`

    # Open a new tmux window and run a bash command to perform a language search on cht.sh:
    # 1. Print the query URL.
    # 2. Use `curl` to fetch results from cht.sh based on the selected language and query.
    # 3. Keep the tmux window open indefinitely with a `while` loop to allow the user to view the output.
    tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
    # If the selected item is not in `~/.tmux-cht-languages`, assume it's a command search:
    # Open a new tmux window and run a bash command to search for a command's cheat sheet on cht.sh.
    # Display the result in `less` for easy navigation.
    tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
fi
