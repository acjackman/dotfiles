# Homebrew Config

After making changes to Brewfiles in this directory, run `chezmoi apply` to deploy changes.

Scripts:
- `run_onchange_darwin-install-packages.sh.tmpl` - runs automatically when any `Brewfile-*` changes; trusts allowlisted taps (see below), then installs packages via `brew bundle`
- `run_onchange_uninstall.sh.tmpl` - handles package uninstallation

## Tap trust

Homebrew 6.0+ refuses to load a third-party tap's (unsandboxed) Ruby until the
tap is explicitly trusted. The install script grants trust, but **only for taps
that are both on the allowlist and referenced by an active Brewfile.**

**When adding a formula/cask from a new third-party tap, add the tap to
`.chezmoidata/homebrew.yaml` (`homebrew.trusted_taps.<profile>`) as well.** The
profiles mirror the Brewfile selection (`base`, `moov`, `personal`, `odin`). If
you skip this, apply prints a warning and Homebrew keeps skipping the tap until
it is vouched for — this is intentional (catches typosquats / unintended taps).

The script auto-trusts a brand-new tap but refuses to trust one whose local
remote no longer matches its canonical `github.com/<user>/homebrew-<repo>` URL
(ownership-change guard) — trust it manually with `brew trust <tap>` if expected.
