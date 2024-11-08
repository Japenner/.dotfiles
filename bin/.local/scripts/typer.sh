#!/usr/bin/env bash

# Description:
# This script simulates typing a command or file path with a customizable delay between keystrokes.
# Useful for automating repetitive typing tasks in a terminal or GUI.
# Usage: ./typer.sh "<command_or_file_path>" [delay_in_ms]
# Example: ./typer.sh "cat /dev/ttyACM3" 100

# Check if the command or file path argument is provided.
if [[ -z "$1" ]]; then
    echo "Usage: $0 \"<command_or_file_path>\" [delay_in_ms]"
    exit 1
fi

# Assign the first argument as the command or file path to type.
command_to_type="$1"

# Assign the second argument as the delay between keystrokes (default to 75 ms if not provided).
delay="${2:-75}"

# Use `xdotool` to simulate typing the specified command or file path with the defined delay.
# --delay $delay: Sets a typing delay between each character in milliseconds.
# "$command_to_type": The command or file path to be typed.
xdotool type --delay "$delay" "$command_to_type"
