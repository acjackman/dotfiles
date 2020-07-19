command -v zoxide &> /dev/null && FOUND_ZOXIDE=1 || FOUND_ZOXIDE=0

if [[ $FOUND_ZOXIDE -eq 1 ]]; then
    eval "$(zoxide init zsh)"
fi

unset FOUND_ZOXIDE
