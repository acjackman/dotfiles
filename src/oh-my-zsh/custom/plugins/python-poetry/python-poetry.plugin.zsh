if [[ -f "$HOME/.poetry/bin/poetry" ]]; then
    export PATH="$HOME/.poetry/bin:$PATH"
    # if [[ -f "$HOME/.zfunc/_poetry" ]]; then
    # else
    #     mkdir -p $HOME/.zfunc
    #     poetry completions zsh > $HOME/.zfunc/_poetry
    # fi
    # fpath+=~/.zfunc
fi
