# Multi-Layered Chezmoi Dotfiles Architecture

## Overview

Restructure dotfiles into a two-layer architecture:
- **Base layer**: Public, shareable dotfiles that others can fork
- **Overlay layer**: Private repo (personal or work) that extends/overrides base

Overlays are **independent** (base+private OR base+work), not stacked.

## Design Constraint

Chezmoi **intentionally does not support** native multi-source layering. From the maintainers:
> "chezmoi makes the opinionated choice to use a single source of truth"

This means any layering solution requires some custom tooling. Below are three approaches, from most native to most flexible.

---

## Option A: Pre-Source-Read Hook (Most Native)

Uses chezmoi's hook mechanism to merge overlay into source before chezmoi reads it.

### Architecture

```
~/.local/share/chezmoi/          # Main chezmoi source (base)
  _overlay/                      # Git submodule (underscore = ignored)
    home/
      dot_config/...
    .chezmoiroot
  dot_config/...
  .chezmoi.toml.tmpl
  .local/bin/merge-overlay.sh   # Hook script
```

### How It Works

1. Overlay repo is git submodule at `_overlay/`
2. `hooks.read-source-state.pre` runs merge script
3. Script copies overlay files into main source tree
4. Chezmoi reads merged source, applies normally
5. Standard `chezmoi apply` works as single command

### Implementation

**Add to `.chezmoi.toml.tmpl`:**
```toml
[hooks.read-source-state.pre]
    command = ".local/share/chezmoi/.merge-overlay.sh"
```

**Create `.merge-overlay.sh`:**
```bash
#!/bin/bash
OVERLAY_DIR="$HOME/.local/share/chezmoi/_overlay"
[[ ! -d "$OVERLAY_DIR" ]] && exit 0

# Resolve .chezmoiroot if present
SOURCE="$OVERLAY_DIR"
[[ -f "$OVERLAY_DIR/.chezmoiroot" ]] && SOURCE="$OVERLAY_DIR/$(cat "$OVERLAY_DIR/.chezmoiroot")"

# Copy overlay files (excluding .git, .chezmoiroot)
rsync -a --exclude='.git' --exclude='.chezmoiroot' "$SOURCE/" "$HOME/.local/share/chezmoi/"
```

### Pros/Cons
- **Pro**: Single `chezmoi apply` command, no wrapper needed
- **Pro**: Others can fork base, ignore submodule
- **Con**: Overlay files copied INTO base repo (messy git status)
- **Con**: Conflicts overwrite silently

---

## Option B: Sequential Applies with Shell Wrapper (Simplest)

Run chezmoi twice with different source directories.

### Architecture

```
~/.local/share/
  chezmoi/                 # Base layer
  chezmoi-overlay/         # Overlay layer (separate repo)
```

### Implementation

**Add to `.zshrc` or shell config:**
```bash
cza() {
    chezmoi apply -S ~/.local/share/chezmoi "$@" && \
    [[ -d ~/.local/share/chezmoi-overlay ]] && \
    chezmoi apply -S ~/.local/share/chezmoi-overlay "$@"
}
```

### Pros/Cons
- **Pro**: No custom tooling, just a shell function
- **Pro**: Completely separate repos, clean git status
- **Con**: Later apply overwrites earlier (no true merge)
- **Con**: Need to remember `cza` not `chezmoi apply`

---

## Option C: Python Merge Tool (Most Flexible) ← Recommended

Custom tool that merges sources before running chezmoi.

### Architecture

```
~/.local/share/
  chezmoi-base/              # Public base (shareable)
  chezmoi-overlay/           # Private overlay

~/.config/chezmoi-layers/
  merged/                    # Ephemeral merged source
  config.toml                # Layer selection
```

### How It Works

1. `dotfiles apply` syncs repos and merges base + overlay
2. Overlay files override base files (same path = overlay wins)
3. Chezmoi runs from merged source directory
4. Full templating works in both layers

### Implementation

**File**: `dot_local/bin/executable_dotfiles.py`

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import shutil
import subprocess
from pathlib import Path

LAYERS_DIR = Path.home() / ".config/chezmoi-layers"
BASE_DIR = Path.home() / ".local/share/chezmoi-base"
OVERLAY_DIR = Path.home() / ".local/share/chezmoi-overlay"
MERGED_DIR = LAYERS_DIR / "merged"

def resolve_chezmoiroot(repo_path: Path) -> Path:
    root_file = repo_path / ".chezmoiroot"
    if root_file.exists():
        return repo_path / root_file.read_text().strip()
    return repo_path

def merge_layers():
    shutil.rmtree(MERGED_DIR, ignore_errors=True)

    # Copy base
    base_source = resolve_chezmoiroot(BASE_DIR)
    shutil.copytree(base_source, MERGED_DIR, dirs_exist_ok=True)

    # Overlay (if exists)
    if OVERLAY_DIR.exists():
        overlay_source = resolve_chezmoiroot(OVERLAY_DIR)
        shutil.copytree(overlay_source, MERGED_DIR, dirs_exist_ok=True)

def main():
    merge_layers()
    subprocess.run(["chezmoi", "apply", "-S", str(MERGED_DIR)])

if __name__ == "__main__":
    main()
```

### Layer Configuration

**File**: `~/.config/chezmoi-layers/config.toml`
```toml
overlay = "personal"  # or "work", selects which overlay repo
```

**File**: Base repo `.chezmoi-layers.toml`
```toml
[overlays.personal]
repo = "git@github.com:acjackman/dotfiles-private.git"

[overlays.work]
repo = "git@github.com:employer/dotfiles-work.git"
```

### Pros/Cons
- **Pro**: True merge with overlay-wins semantics
- **Pro**: Full templating in both layers
- **Pro**: Clean separation, proper git status in each repo
- **Pro**: Extensible (add smart merge strategies later)
- **Con**: Requires wrapper command (`dotfiles` not `chezmoi`)
- **Con**: More complex initial setup

---

## Recommendation: Option C (Python Merge Tool)

Given your requirements:
- Full templating in overlays ✓
- Single command experience ✓
- Others can fork base ✓
- Clean repo separation ✓

Option C provides the most flexibility while remaining bootstrappable with uv.

---

## Alternative Tools Considered

| Tool | Multi-Layer | Templating | Notes |
|------|------------|------------|-------|
| **Home-Manager (Nix)** | Excellent | Full Nix | Steep learning curve, but best native layering |
| **VCSH + MR** | Excellent | None | Lightweight parallel repos, add templating via hooks |
| **RCM** | Good | Limited | Easy migration, `-d` flag for multiple sources |
| **Bare Git** | Flexible | None | Maximum control, requires discipline |

Staying with chezmoi + merge tool is recommended given existing investment in chezmoi templating.

---

## Common Elements (All Options)

### Overlay Repo Structure

```
dotfiles-overlay/
  .chezmoiroot              # Contains: home
  home/
    dot_config/
      zsh/
        functions/
          ,private-func
      sesh/
        sessions.d/
          80-personal.toml
    private_ssh/
      config.tmpl
```

### Secrets Handling

Each layer uses its own 1Password vault references:
- Base: Shared/public vault items
- Overlay: Personal or work vault

### Template Data Merging

Both layers can have `.chezmoidata.*` files. When merged, chezmoi combines them (last file wins for conflicts).

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `dot_local/bin/executable_dotfiles.py` | Create | Merge tool (Option C) |
| `.chezmoi-layers.toml` | Create | Overlay repo definitions |
| `README.md` | Update | Document layer system for forks |
| `.chezmoiignore` | Update | Ignore `_overlay/`, layer configs |

---

## Migration Path

1. Create merge tool in current repo
2. Test with existing structure (no overlay)
3. Create personal overlay repo with `.chezmoiroot`
4. Move personal-specific files to overlay
5. Migrate work overlay from existing chezmoi-local
6. Update bootstrap script for new structure

## Verification

1. `dotfiles diff` - Preview changes
2. `dotfiles apply` - Full apply
3. Test base-only (no overlay) - must work for forks
4. Test with each overlay type
