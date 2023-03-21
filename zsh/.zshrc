####################### Initial setup ########################

# Load custom executable functions
source ~/.functions

######################### Oh My Zsh ##########################

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"
ZSH_TMUX_AUTOSTART="true"
SPACESHIP_PROMPT_ADD_NEWLINE="true"
SPACESHIP_CHAR_SYMBOL="\uf0e7"
SPACESHIP_CHAR_PREFIX="\uf296"
SPACESHIP_CHAR_SUFFIX=(" ")
SPACESHIP_CHAR_COLOR_SUCCESS="yellow"
SPACESHIP_PROMPT_DEFAULT_PREFIX="$USER"
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW="true"
SPACESHIP_USER_SHOW="true"

plugins=(
  asdf
  git
  zsh-autosuggestions
  zsh-nvm
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

######################### User config #########################

source ~/.zsh_profile
source ~/.aliases

# Setup zsh for asdf
if [ -f /usr/local/opt/asdf/asdf.sh ]; then
  source /usr/local/opt/asdf/asdf.sh
fi

########################### Exports ###########################

export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export PATH="~/bin:$PATH"

export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
export PATH=~/.local/bin:$PATH
export PATH=$PATH:~/bin

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export EDITOR="code"
export BUNDLER_EDITOR="code"

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

##############################################################

# https://starship.rs/
eval "$(starship init zsh)"
