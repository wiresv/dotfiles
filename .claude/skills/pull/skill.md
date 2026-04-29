---
name: pull
description: Pull the latest changes from the remote for the current branch.
---

Pull the latest changes from the remote into the current local branch.

## Pre-flight checks (abort with explanation if any fail)

- Verify this is a git repository
- Confirm HEAD is not detached
- Confirm the current branch has an upstream tracking branch (`git rev-parse --abbrev-ref --symbolic-full-name @{u}`) — if not, report that there is no upstream to pull from and stop

## Check for uncommitted work

Run `git status --porcelain` to detect uncommitted changes (staged, unstaged, or untracked).

If there are uncommitted changes:
- Report what is dirty (briefly — file count and types of changes, not a full listing)
- Stash automatically with a descriptive message: `git stash push -m "pull: auto-stash before pulling <branch>"`
- Remember that a stash was created so it can be popped after the pull

## Pull

- Run `git pull --ff-only` to fast-forward the branch
- If fast-forward fails because the branch has diverged:
  - Do NOT force-pull, rebase, or merge automatically
  - Report the divergence clearly: how many commits ahead and behind (`git rev-list --left-right --count @{u}...HEAD`)
  - Ask the user whether they want to merge (`git pull --no-rebase`), rebase (`git pull --rebase`), or abort
  - Wait for the user's decision before proceeding

## Post-pull

- If a stash was created earlier, pop it: `git stash pop`
  - If the pop produces conflicts, report them clearly and stop — do not resolve stash conflicts automatically
- Show a brief summary: what branch was updated, how many new commits were pulled (`git log --oneline @{1}..HEAD` where `@{1}` is the pre-pull position), and whether stashed changes were restored
