# Function to display the current Git branch in the prompt if applicable
git_prompt_info() {
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n $current_branch ]]; then
    echo " %{$fg_bold[green]%}$current_branch%{$reset_color%}"
  fi
}

# Enable prompt substitution for dynamic prompt components
setopt promptsubst

# Prompt configuration
if ! env | grep -q '^PS1='; then
  PS1='${SSH_CONNECTION+"%{$fg_bold[green]%}%n@%m:"}%{$fg_bold[blue]%}%c%{$reset_color%}$(git_prompt_info) %# '
fi

# Include indicators for the exit status of the last command
PS1='%(?.%F{green}.%F{red})%B%n@%m%b%f:%F{blue}%c%f $(git_prompt_info) %# '
