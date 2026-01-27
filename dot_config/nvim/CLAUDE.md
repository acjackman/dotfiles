# Neovim Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_restore_nvim.sh.tmpl` script runs automatically when `data/nvim/lazy-lock.json` changes, restoring Neovim plugins via `nvim --headless "+Lazy! restore"`.
