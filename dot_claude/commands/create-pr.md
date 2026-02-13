# Create Pull Request

Create a draft pull request using the `gh` CLI that follows the repository's PR template.

## Instructions

1. First, check the current git state:
   - Run `git status` to see uncommitted changes
   - Run `git log origin/main..HEAD` (or appropriate base branch) to see commits to be included
   - Run `git diff origin/main...HEAD` to understand the full scope of changes

2. Check if the repository has a PR template (check in this order):
   - `.github/pull_request_template.md` (case-insensitive filename)
   - `.github/PULL_REQUEST_TEMPLATE/` directory (multiple templates)
   - `docs/pull_request_template.md` (case-insensitive filename)
   - `docs/PULL_REQUEST_TEMPLATE/` directory (multiple templates)
   - `pull_request_template.md` in repo root (case-insensitive filename)
   - `PULL_REQUEST_TEMPLATE/` directory in repo root (multiple templates)
   - Use the first match found; if a template exists, read it and use its structure

3. If there are uncommitted changes that should be included, prompt about committing them first.

4. Check if the current branch tracks a remote and is pushed:
   - If not pushed, push with `git push -u origin HEAD`

5. Create the draft PR using `gh pr create`:
   - Always use `--draft` flag
   - Use `--title` with a concise, descriptive title
   - Use `--body` with content following the PR template structure
   - If no template exists, use this format:
     ```
     ## Summary
     <brief description of changes>

     ## Changes
     <bullet points of key changes>

     ## Testing
     <how to test the changes>
     ```

6. Use a HEREDOC for the body to preserve formatting:
   ```bash
   gh pr create --draft --title "Title here" --body "$(cat <<'EOF'
   ## Summary
   ...
   EOF
   )"
   ```

7. After creating the PR, output the PR URL so the user can access it.

## Important

- Always create PRs as **drafts** (`--draft` flag)
- Always follow the repository's PR template if one exists
- Never force push or modify git config
- If the PR template has required sections, fill them all out based on the changes
