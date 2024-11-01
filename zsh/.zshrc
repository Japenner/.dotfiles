# Enable Powerlevel10k instant prompt. This should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
prompt_file="$cache_dir/p10k-instant-prompt-${USER}.zsh"
if [[ -r "$prompt_file" ]]; then
  source "$prompt_file"
fi

# ================== Initial Setup ================== #

# Load custom functions if any exist
for file in ~/zsh/functions/*(.N); do
  source "$file"
done

# ======= Paths and Environment-Specific Configurations ======= #

# Custom PATH additions and environment variables
export PATH="$HOME/bin:/usr/local/opt/openssl@1.1/bin:/usr/local/opt/openssl/lib:$HOME/.local/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$GOPATH/bin:$PATH"
export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/opt/openssl/lib" # OpenSSL paths
export GOPATH="$HOME/go"                                       # Set GOPATH for Go

# Load asdf if available
[ -f /usr/local/opt/asdf/asdf.sh ] && source /usr/local/opt/asdf/asdf.sh

# =================== Oh My Zsh ===================== #

export ZSH="$HOME/.oh-my-zsh"           # Path to Oh My Zsh installation
ZSH_THEME="powerlevel10k/powerlevel10k" # Set theme to Powerlevel10k
ZSH_TMUX_AUTOSTART="true"               # Auto-start tmux with Zsh

# Plugins for Oh My Zsh
plugins=(
  ansible
  asdf
  git
  node
  ruby
  docker
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  history
  fzf
  z
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ================ Zsh Configuration ================ #

# Load all .zsh configuration files from the configs directory
for config_file in ~/zsh/configs/*(.N); do
  source "$config_file"
done

# ================ Load Additional Configs ================ #

# Load other configuration files if available
[ -f ~/.zsh_profile ] && source ~/.zsh_profile
[ -f ~/.aliases ] && source ~/.aliases

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
. "$HOME/.asdf/asdf.sh"
