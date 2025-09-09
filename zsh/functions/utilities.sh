#!/usr/bin/env bash

# Generate a new script from the template
generate_script() {
  script_name=${1:-"new-script.sh"}
  templates_path="${DOTFILES}/__resources__/templates"
  cat ${templates_path}/example-script.sh > $script_name
  chmod +x $script_name
  echo "Created $script_name"
}

# Open Google Chrome on macOS or Linux
open_chrome() {
  local urls=("$@")

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use `open` to launch Google Chrome
    if [[ ${#urls[@]} -eq 0 ]]; then
      open -a "Google Chrome"
    else
      for url in "${urls[@]}"; do
        open -a "Google Chrome" "$url"
      done
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: Use `google-chrome` or `chromium` based on availability
    local chrome_cmd=""
    if command -v google-chrome &>/dev/null; then
      chrome_cmd="google-chrome"
    elif command -v chromium &>/dev/null; then
      chrome_cmd="chromium"
    else
      echo "Google Chrome or Chromium is not installed on this system."
      return 1
    fi

    if [[ ${#urls[@]} -eq 0 ]]; then
      $chrome_cmd &
    else
      $chrome_cmd "${urls[@]}" &
    fi
  else
    echo "Unsupported OS: $OSTYPE"
    return 1
  fi
}

# Display NATO phonetic alphabet
print_nato_alphabet() {
  cat <<EOF
A Alpha
B Bravo
C Charlie
D Delta
E Echo
F Foxtrot
G Golf
H Hotel
I India
J Juliet
K Kilo
L Lima
M Mike
N November
O Oscar
P Papa
Q Quebec
R Romeo
S Sierra
T Tango
U Uniform
V Victor
W Whiskey
X X-ray
Y Yankee
Z Zulu
EOF
}

# Set clipboard command based on OS
set_clipboard_command() {
  if command -v pbcopy >/dev/null 2>&1; then
    clipboard_cmd="pbcopy" # macOS
  elif command -v xclip >/dev/null 2>&1; then
    clipboard_cmd="xclip -selection clipboard" # Linux
  elif command -v clip.exe >/dev/null 2>&1; then
    clipboard_cmd="clip.exe" # Windows (Git Bash)
  else
    echo "Error: No suitable clipboard command found."
    return 1
  fi
}

# Add new todo item
todo_add() {
  if [[ -z "$1" ]]; then
    echo "- [ ] " >> "$DOTFILES/.TODO" && $CODE_EDITOR "$DOTFILES/.TODO"
  else
    echo "- [ ] $*" >> "$DOTFILES/.TODO"
  fi
}
