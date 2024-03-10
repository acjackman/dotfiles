#!/usr/bin/env sh
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/

# Pickup hoembrew command with no config
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

# for brew_path in "/home/linuxbrew/.linuxbrew/bin/brew" "/opt/homebrew/bin/brew"; do
#   if [[ -x "$brew_path" ]]; then
#     eval "$($brew_path shellenv)"
#     break
#   fi
# done

# Doesn't let you press Ctrl-C
function ctrl_c() {
	echo -e "\renter nil to drop to normal prompt"
}

trap ctrl_c SIGINT


no_of_terminals=$(tmux list-sessions 2>/dev/null | wc -l)
if [[ $no_of_terminals -eq 0 ]]; then
    tmux new-session -s "main"
else
    IFS=$'\n'
    output=($(tmux list-sessions))
    output_names=($(tmux list-sessions -F\#S))
    k=1
    echo "Choose the terminal to attach: "
    for i in "${output[@]}"; do
        echo "$k - $i"
        ((k++))
    done
    echo
    echo "Create a new session by entering a name for it"
    read -r input
    if [[ $input == "" ]]; then
        tmux new-session
    elif [[ $input == 'nil' ]]; then
        exit 1
    elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -le $no_of_terminals ]]; then
        terminal_name="${output_names[input - 1]}"
        tmux attach -t "$terminal_name"
    else
        tmux new-session -s "$input"
    fi
fi
exit 0
