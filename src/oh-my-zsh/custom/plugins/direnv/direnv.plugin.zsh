command -v direnv &> /dev/null && FOUND_DIRENV=1 || FOUND_DIRENV=0

if [[ $FOUND_DIRENV -eq 1 ]]; then
    eval "$(direnv hook zsh)"
fi

unset FOUND_DIRENV
