#!/bin/bash

# From https://gist.github.com/ChillingHsu/513f9d0333f03592576338f90bc2f898

BG_RED=`tput setaf 1`
BG_GREEN=`tput setaf 2`
BOLD=`tput bold`
RESET=`tput sgr0`

EMACS='/Applications/Emacs.app'

if [ -f "/opt/homebrew/bin/emacsclient" ]; then
  EMACS_CLIENT='/opt/homebrew/bin/emacsclient'
else
  EMACS_CLIENT='/usr/local/bin/emacsclient'
fi


DEFAULT_EVAL='(switch-to-buffer "*scratch*")'
DEFAULT_ARGS="-e"
NO_WAIT='-n'


function run_client(){
    if [ $# -ne 0 ]
    then
      if [[ "$@" =~ (^|[[:space:]])-nw($|[[:space:]]) ]]
      then
        ${EMACS_CLIENT} $@
      else
        ${EMACS_CLIENT} ${NO_WAIT} $@
      fi
    else
        ${EMACS_CLIENT} ${NO_WAIT} ${DEFAULT_ARGS} "${DEFAULT_EVAL}" &> /dev/null
    fi
}

echo -e "Checking Emacs server status...\c"
if pgrep Emacs &> /dev/null
then
    echo "${BOLD}${BG_GREEN}Active${RESET}"
    echo -e "Connecting..."
    run_client $*
    # echo "${BOLD}${BG_GREEN}DONE${RESET}"
else
    echo "${BOLD}${BG_RED}Inactive${RESET}"
    echo -e "Emacs server is starting...\c"
    open -a ${EMACS}
    echo "${BOLD}${BG_GREEN}DONE${RESET}"

    echo -e "Trying connecting..."
    until run_client $* &> /dev/null; [ $? -eq 0 ]
    do
        sleep 1
        echo Retrying...
    done
    # echo "${BOLD}${BG_GREEN}DONE${RESET}"
fi
