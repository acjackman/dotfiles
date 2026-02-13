# Git

- Never use `git -C`. You are always launched inside the target repository or worktree, so plain `git` commands already operate on the correct repo. This applies even in bare-repo + worktree layouts where the worktree is a subdirectory of a non-repo parent. Using `git -C` breaks automatic permission grants.
