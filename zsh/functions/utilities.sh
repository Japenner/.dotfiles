#!/usr/bin/env bash

# Open Google Chrome on macOS or Linux
open_chrome() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use `open` to launch Google Chrome
    open -a "Google Chrome"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: Use `google-chrome` or `chromium` based on availability
    if command -v google-chrome &>/dev/null; then
      google-chrome &
    elif command -v chromium &>/dev/null; then
      chromium &
    else
      echo "Google Chrome or Chromium is not installed on this system."
      return 1
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
