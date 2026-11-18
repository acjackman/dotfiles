export HOMEBREW_GITHUB_API_TOKEN="$(security find-generic-password -a "$USER" -s "HOMEBREW_GITHUB_API_TOKEN" -w 2>/dev/null)"
