# Navi Cheat File Syntax

## File Format

Navi cheat files use the `.cheat` extension and follow a specific syntax.

## Basic Structure

```
% tag1, tag2

# Description of command
command --with --flags

# Another command description
another-command <variable>
```

## Special Characters

### `%` - Tags
First line defines tags for filtering/organizing cheats:
```
% git, version-control
```

### `#` - Description
Lines starting with `#` describe the following command:
```
# List all branches
git branch -a
```

### `;` - Comments
Lines starting with `;` are ignored (true comments, not shown to user).

### `:` - Variable Options (IMPORTANT)
Colons define variable options and have special meaning:
```
# Delete a branch
git branch -d <branch>

$ branch: git branch --format='%(refname:short)'
```

**ESCAPE COLONS IN COMMANDS**: If your command contains a literal colon (like URLs), escape it with a backslash:
```
# Correct - escaped colon
curl https\://example.com/api

# Wrong - colon will be interpreted as variable separator
curl https://example.com/api
```

### `<variable>` - Variables
Angle brackets define interactive variables:
```
# Connect to server
ssh <user>@<host>
```

### `$` - Variable Definitions
Define how variables get their values:
```
$ user: echo -e "root\nadmin\nubuntu"
$ host: cat ~/.ssh/known_hosts | cut -f1 -d' '
```

## Variable Definition Syntax

```
$ variable_name: command to generate options
$ variable_name: echo -e "option1\noption2\noption3"
$ variable_name: command --- --flag1 --flag2
```

Options after `---`:
- `--hierarchical` - treat values as hierarchical (first column is category)
- `--multi` - allow multiple selections
- `--expand` - expand variable in preview

## Multi-line Commands

Use `\` at end of line:
```
# Long command
docker run \
  --name container \
  -v /host:/container \
  image
```

## Common Pitfalls

1. **Unescaped colons in URLs** - Always use `\:` in URLs
2. **Unescaped angle brackets** - Use `\<` and `\>` for literal brackets
3. **Missing blank line** - Separate command blocks with blank lines
