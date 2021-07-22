if command -v poetry &> /dev/null && [[ "$(uname -r)" != *icrosoft* ]]; then
    FOUND_POETRY=1
else
    FOUND_POETRY=0
fi


if [[ $FOUND_PYENV -eq 1 ]]; then
    if [[ -f "$HOME/.poetry/bin/poetry" ]]; then
        export PATH="$HOME/.poetry/bin:$PATH"
        # if [[ -f "$HOME/.zfunc/_poetry" ]]; then
        # else
        #     mkdir -p $HOME/.zfunc
        #     poetry completions zsh > $HOME/.zfunc/_poetry
        # fi
        # fpath+=~/.zfunc
    fi
fi
unset FOUND_POETRY
