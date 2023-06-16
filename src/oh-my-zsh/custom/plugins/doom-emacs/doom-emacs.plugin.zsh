if [[ -e "$HOME/.emacs.d/bin" ]]; then
  export PATH="$HOME/.emacs.d/bin:$PATH"
fi

if [[ -e "$HOME/${XDG_CONFIG_HOME:-.config}/emacs/bin" ]]; then
  export PATH="$HOME/${XDG_CONFIG_HOME:-.config}/emacs/bin:$PATH"
fi
