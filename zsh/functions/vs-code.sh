#!/usr/bin/env bash

# Function to locate the VS Code settings.json file based on OS
find_vscode_settings() {
    local settings_path=""

    # Detect the OS and set the path accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [[ -f "$HOME/Library/Application Support/Code/User/settings.json" ]]; then
            settings_path="$HOME/Library/Application Support/Code/User/settings.json"
        elif [[ -f "$HOME/Library/Application Support/Code - Insiders/User/settings.json" ]]; then
            settings_path="$HOME/Library/Application Support/Code - Insiders/User/settings.json"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
            settings_path="$HOME/.config/Code/User/settings.json"
        elif [[ -f "$HOME/.config/Code - Insiders/User/settings.json" ]]; then
            settings_path="$HOME/.config/Code - Insiders/User/settings.json"
        fi
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows (assuming a typical installation path)
        if [[ -f "$APPDATA/Code/User/settings.json" ]]; then
            settings_path="$APPDATA/Code/User/settings.json"
        elif [[ -f "$APPDATA/Code - Insiders/User/settings.json" ]]; then
            settings_path="$APPDATA/Code - Insiders/User/settings.json"
        fi
    fi

    # Output the result if found
    if [[ -n "$settings_path" ]]; then
        echo $settings_path
    fi
}
