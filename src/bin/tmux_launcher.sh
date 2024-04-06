#!/bin/sh
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/

# Pickup hoembrew command with no config

if [[ -x "/opt/homebrew/bin/brew" ]]; then
    PATH="$PATH:/opt/homebrew/bin"
fi

# # Doesn't let you press Ctrl-C
# function ctrl_c() {
# 	echo -e "\renter nil to drop to normal prompt"
# }
#
# trap ctrl_c SIGINT
#
#
# no_of_terminals=$(tmux list-sessions 2>/dev/null | wc -l)
# if [[ $no_of_terminals -eq 0 ]]; then
#     tmux new-session -s "main"
# else
#     IFS=$'\n'
#     output=($(tmux list-sessions))
#     output_names=($(tmux list-sessions -F\#S))
#     k=1
#     echo "Choose the terminal to attach: "
#     for i in "${output[@]}"; do
#         echo "$k - $i"
#         ((k++))
#     done
#     echo
#     echo "Create a new session by entering a name for it"
#     read -r input
#     if [[ $input == "" ]]; then
#         tmux new-session
#     elif [[ $input == 'nil' ]]; then
#         # Run the default shell
#         $SHELL
#     elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -le $no_of_terminals ]]; then
#         terminal_name="${output_names[input - 1]}"
#         tmux attach -t "$terminal_name"
#     else
#         tmux new-session -s "$input"
#     fi
# fi

# exec /bin/zsh -l
tmux new-session -A -D -s main
# exec /usr/bin/env zsh
# exit 0
