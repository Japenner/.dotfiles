# Directory navigation settings
setopt autocd      # Change to directory by name without `cd`
setopt autopushd   # Automatically add directories to the directory stack
setopt pushdminus  # Reverse pushd directory order
setopt pushdsilent # Suppress directory stack output on changes
setopt pushdtohome # Push current directory onto stack when `cd ~`
setopt cdablevars  # Use variables as directory paths in `cd`

DIRSTACKSIZE=5 # Limit directory stack to 5 entries

# Make directory stack navigation easier with helpful aliases
alias d='dirs -v' # Display the directory stack
alias 1='cd -1'   # Quick access to recent directories
