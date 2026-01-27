# Tmux Config

After making changes to files in this directory, run `chezmoi apply` to deploy and automatically reload the tmux config.

The `run_onchange_after_reload-tmux.sh.tmpl` script runs automatically when `tmux.conf` or `tmux.reset.conf` changes, reloading the config in any active tmux session.
