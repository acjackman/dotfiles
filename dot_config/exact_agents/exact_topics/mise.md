# Mise

`mise` manages language runtimes and project tasks. It replaces tools like nvm, pyenv, and rbenv.

## Runtimes

- Use `mise` to install and manage language runtimes and tools

## Config

- Use the project's committed mise config (e.g., `mise.toml`, `.mise.toml`) when one exists
- If the project doesn't have mise config, add a local config at `.config/mise.local.toml` instead of committing one — this avoids adding mise as a project dependency others didn't opt into
- `.config/mise.local.toml` is also the right place for personal overrides on top of an existing committed config

## Tasks

Define `mise` tasks for common repo actions so `mise run <tab>` provides discoverability.

### Standard lifecycle tasks
- `test`, `lint`, `format`, `build` — wrap the project's native commands

### Project-specific tasks
- `deploy`, `seed-db`, `generate-types`, etc. — whatever the project needs

### Conventions
- Tasks should wrap project-native commands, providing a consistent `mise run` interface across repos
- Alias frequently-used tasks: `mise run` can be invoked as `,r` (shell alias)
