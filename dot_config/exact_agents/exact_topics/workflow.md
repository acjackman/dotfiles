# Workflow

## Pull Requests

- Always create PRs as drafts (`gh pr create --draft`)
- Include a summary and test plan in the PR body
- Follow the repo's PR template if one exists

## Testing

- Prefer TDD red/green cycle: write a failing test, make it pass, refactor
- Test critical paths and edge cases
- Be pragmatic — don't test obvious glue code or trivial wrappers
- If no test infrastructure exists in the project, ask before setting it up

## CI

- Follow existing CI patterns in the project
- Don't modify CI configuration without discussing first
