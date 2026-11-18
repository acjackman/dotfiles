# Sketchybar Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_after_reload-sketchybar.sh.tmpl` script runs automatically when `sketchybarrc` changes, reloading sketchybar via `sketchybar --reload`.

Additional scripts in subdirectories:
- `plugins/run_onchange_aerospace-plugin.sh` - aerospace integration plugin
- `data/run_onchange_icon_map.sh` - icon mapping updates
