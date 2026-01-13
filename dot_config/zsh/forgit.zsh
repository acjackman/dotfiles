# -*- mode: sh -*-
# Forgit configuration
# https://github.com/wfxr/forgit

# =============
# Display Settings
# =============
export FORGIT_PREVIEW_CONTEXT=5
export FORGIT_FULLSCREEN_CONTEXT=10

# =============
# Pager Configuration
# =============
# Use delta for better diff viewing if available
if command -v delta &> /dev/null; then
  export FORGIT_DIFF_PAGER="delta --line-numbers"
  export FORGIT_SHOW_PAGER="delta --line-numbers"
else
  export FORGIT_DIFF_PAGER="less -R"
  export FORGIT_SHOW_PAGER="less -R"
fi

# =============
# FZF Options
# =============
# Global FZF options for forgit (no --height to use fullscreen)
export FORGIT_FZF_DEFAULT_OPTS="
  --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
  --preview-window='right:60%'
"

# Log-specific FZF options
export FORGIT_LOG_FZF_OPTS="
  --preview-window='right:60%'
  --bind='ctrl-d:preview-half-page-down'
  --bind='ctrl-u:preview-half-page-up'
"

# =============
# Git Options
# =============
# Show all branches in log by default
export FORGIT_LOG_GIT_OPTS='--graph --all --decorate'

# =============
# Aliases
# =============
# Uncomment and customize if you want different command names
# export forgit_log=glo
# export forgit_diff=gd
# export forgit_add=ga
# export forgit_reset_head=grh
# export forgit_ignore=gi
# export forgit_checkout_file=gcf
# export forgit_checkout_branch=gcb
# export forgit_checkout_commit=gco
# export forgit_revert_commit=grc
# export forgit_clean=gclean
# export forgit_stash_show=gss
# export forgit_stash_push=gsp
# export forgit_cherry_pick=gcp
# export forgit_rebase=grb
# export forgit_fixup=gfu
# export forgit_blame=gbl

# Disable all default aliases (uncomment if you prefer to define your own)
# export FORGIT_NO_ALIASES=1
