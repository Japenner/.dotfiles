# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ================== Initial Setup ================== #

[ -f ~/.functions ] && source ~/.functions # Load custom functions if available

# =================== Oh My Zsh ===================== #

export ZSH="$HOME/.oh-my-zsh"           # Path to Oh My Zsh installation
ZSH_THEME="powerlevel10k/powerlevel10k" # Set theme (e.g., Powerlevel10k for customization)
ZSH_TMUX_AUTOSTART="true"               # Start tmux automatically with Zsh

# Plugins for Oh My Zsh
plugins=(
  ansible
  asdf
  git
  node
  ruby
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ================ Zsh Configuration ================ #

# History and navigation configurations
HISTFILE=~/.zsh_history       # File to store command history
HISTSIZE=10000                # Maximum history entries in memory
SAVEHIST=10000                # Maximum history entries to save to file
setopt INC_APPEND_HISTORY     # Share command history across sessions
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Remove duplicate entries first
setopt HIST_FIND_NO_DUPS      # Ignore duplicate entries when searching history

# Enable command correction and autosuggestions
setopt CORRECT                          # Auto-correct minor typos
setopt AUTO_CD                          # Change to a directory without needing `cd`
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=10" # Color for autosuggestions

# ================ Load Configs and Plugins ================ #

# Load additional config files if available
[ -f ~/.zsh_profile ] && source ~/.zsh_profile
[ -f ~/.aliases ] && source ~/.aliases

# Load asdf if available
[ -f /usr/local/opt/asdf/asdf.sh ] && source /usr/local/opt/asdf/asdf.sh

# Load Starship prompt if installed
# command -v starship >/dev/null && eval "$(starship init zsh)"

# ======= Paths and Environment-Specific Configurations ======= #

export PATH="$HOME/bin:/usr/local/opt/openssl@1.1/bin:/usr/local/opt/openssl/lib:$HOME/.local/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$GOPATH/bin:$PATH"

export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/opt/openssl/lib" # Library paths for OpenSSL
export EDITOR="code"                                           # Set default editor to VS Code
export BUNDLER_EDITOR="code"                                   # Set Bundler editor to VS Code
export GOPATH="$HOME/go"                                       # Set GOPATH for Go
. "$HOME/.asdf/asdf.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
