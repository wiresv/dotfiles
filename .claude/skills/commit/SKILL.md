---
name: commit
description: Analyze recent git changes, stage them, and commit with a precise message.
---

Review and commit the current code changes in this repository.

## Pre-flight checks (abort with explanation if any fail)
- Verify this is a git repository
- Confirm no merge conflicts exist (check for conflict markers or merge state)
- Confirm HEAD is not detached
- Confirm there are actual changes to commit (staged or unstaged or untracked)

## Stage changes
- Run `git status` and `git diff` to understand all current changes
- Stage files individually by name — never use `git add .` or `git add -A`
- Skip files that should not be committed: .env files, credentials, secrets, private keys, large binaries, build output, node_modules, and similar artifacts
- If all changes are in files that should be skipped, explain why and stop

## Commit
- Check recent git log to match this repo's commit message style and conventions
- Write a single concise commit message: imperative mood, focus on the what and why
- Do not append any trailers, signatures, or metadata lines (Co-Authored-By, Signed-off-by, etc.)
- Use a HEREDOC to pass the commit message to `git commit -m`
- If a pre-commit hook fails, fix the issue and create a new commit (never amend, never --no-verify)
