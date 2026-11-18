# Worktrunk Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_after_merge-worktrunk-config.py.tmpl` script runs automatically when the script itself changes. It merges chezmoi-managed settings with the machine-local `[projects]` section, preserving local project definitions while updating managed configuration.
