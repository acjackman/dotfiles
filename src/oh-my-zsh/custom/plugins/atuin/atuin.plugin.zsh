#!/usr/bin/env zsh
command -v atuin &> /dev/null && FOUND_ATUIN=1 || FOUND_ATUIN=0

if [[ $FOUND_ATUIN -eq 1 ]]; then
    # export ATUIN_NOBIND="true"
    eval "$(atuin init zsh)"

    bindkey '^r' _atuin_search_widget
fi

unset FOUND_ATUIN
