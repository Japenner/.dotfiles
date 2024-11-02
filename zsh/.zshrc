if [[ "$OSTYPE" == "darwin"* ]]; then
    source ~/.dotfiles/zsh/.zshrc.macos
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source ~/.dotfiles/zsh/.zshrc.linux
fi
