---
name: cpr
description: Commit current changes (via the commit skill), push the branch, and open a pull request against the main branch.
---

Commit the current changes and open a pull request. Use this from any branch — including a worktree branch — when you want to land work on `main` (or whatever the repo's default branch is) via a PR.

## Step 1 — Commit

Invoke the `commit` skill to stage and commit the current changes. Follow its rules exactly (no `git add .`, no trailers, no `--no-verify`, no amend).

If `commit` aborts (no changes, merge conflicts, detached HEAD, etc.), stop here and surface the reason — there is nothing to PR.

If there are *already* committed changes ahead of the base branch but no uncommitted changes, skip straight to Step 2.

## Step 2 — Determine base branch and branch state

Run these in parallel:
- `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` — the PR target
- `git rev-parse --abbrev-ref HEAD` — current branch
- `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no-upstream"` — upstream tracking
- `git log --oneline <base>..HEAD` — commits that will be in the PR (use the default branch name from the first command)

Abort with an explanation if:
- Current branch *is* the default branch — refuse to PR `main` into `main`. Tell the user to switch to a feature branch first.
- There are zero commits ahead of the base branch — nothing to PR.

## Step 2.5 — Ensure a descriptive branch name

Claude Code worktrees generate random branch names (e.g., `worktree-mighty-sprouting-honey`) that are meaningless in PR history. Detect and fix these before pushing.

**When to rename:** if the current branch name matches any of these patterns:
- Starts with `worktree-`
- Matches the three-word `<adjective>-<gerund>-<noun>` pattern typical of auto-generated worktree names (e.g., `quizzical-juggling-swan`, `resilient-wobbling-glacier`)
- Is otherwise clearly non-descriptive of the actual changes

**How to rename:**
1. Analyze the commits in the PR range (`git log <base>..HEAD` and `git diff <base>...HEAD --stat`) to understand what changed.
2. Generate a branch name that is:
   - **Brief:** 2–5 words joined by hyphens, ideally under 40 characters total.
   - **Descriptive:** conveys the nature of the change at a glance.
   - **Conventional:** use a prefix matching the change type: `feat/`, `fix/`, `refactor/`, `docs/`, `chore/`, `test/`, `perf/`, `ci/` (e.g., `fix/calendar-date-parsing`, `feat/patient-api-patch`, `docs/update-claude-md`).
   - **Lowercase, hyphen-separated** — no underscores, no uppercase, no special characters.
3. Rename: `git branch -m <old-name> <new-name>`
4. The branch must NOT have been pushed yet (no upstream). If it has already been pushed under the old name, do NOT rename — use it as-is to avoid confusion.

**When to keep the current name:** if the branch already has a descriptive name chosen by the user, or if it has already been pushed to the remote, leave it alone.

## Step 3 — Push the branch

- If the branch has no upstream: `git push -u origin <current-branch>`
- If it has an upstream and is ahead of remote: `git push`
- If it is up to date with the remote: skip
- Never force-push. If the push is rejected as non-fast-forward, stop and ask the user how to proceed (do not pass `--force` or `--force-with-lease` on your own).

## Step 4 — Draft the PR title and body

Inspect ALL commits in the PR range, not just the latest:
- `git log <base>..HEAD` for commit messages
- `git diff <base>...HEAD --stat` for the file-level shape of the change

Write a PR title and body following this repo's conventions (peek at recent merged PRs with `gh pr list --state merged --limit 5` if you need a style reference):
- **Title:** under 70 characters, imperative mood, summarizes the whole branch (not just the last commit).
- **Body:** use the standard format below. Keep it tight — bullets, not paragraphs.

```markdown
## Summary
- <1-3 bullets covering what changed and why>

## Test plan
- [ ] <bulleted checklist of what was verified or still needs verifying>
```

Do not append trailers, signatures, or "Generated with" lines.

## Step 5 — Create the PR

Run:

```
gh pr create --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

Pass the body via HEREDOC to preserve formatting. Do NOT pass `--draft` unless the user explicitly asked for a draft PR.

## Step 6 — Report

Print the PR URL returned by `gh pr create` so the user can click it. Do not auto-merge, do not request reviewers, do not add labels — leave those decisions to the user.

## Notes
- If `gh` is not installed or not authenticated, stop and tell the user to run `gh auth login`.
- If the working directory is a git worktree, everything above still applies — the worktree's branch is what gets pushed. Do not switch to the main worktree, do not delete the worktree, do not clean up the branch. The user manages worktree lifecycle separately.
