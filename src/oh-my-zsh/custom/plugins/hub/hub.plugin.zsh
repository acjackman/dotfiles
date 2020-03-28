command -v hub &> /dev/null && FOUND_HUB=1 || FOUND_HUB=0

if [[ $FOUND_HUB -eq 1 ]]; then
    eval "$(hub alias -s)"
fi

unset FOUND_HUB
