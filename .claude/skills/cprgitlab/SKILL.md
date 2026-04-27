---
name: cprgitlab
description: Commit current changes (via the commit skill), push the branch, and open a merge request against the main branch on GitLab using glab.
---

GitLab counterpart of `/cpr`. Commits the current changes and opens a merge request via `glab`. Use this from any branch — including a worktree branch — when the repo's remote is on GitLab and you want to land work on `main` (or whatever the repo's default branch is) via an MR.

If the repo's `origin` is on GitHub, use `/cpr` instead.

## Step 1 — Commit

Invoke the `commit` skill to stage and commit the current changes. Follow its rules exactly (no `git add .`, no trailers, no `--no-verify`, no amend).

If `commit` aborts (no changes, merge conflicts, detached HEAD, etc.), stop here and surface the reason — there is nothing to MR.

If there are *already* committed changes ahead of the base branch but no uncommitted changes, skip straight to Step 2.

## Step 2 — Determine base branch and branch state

Run these in parallel:
- `glab repo view -F json | jq -r .default_branch` — the MR target
- `git rev-parse --abbrev-ref HEAD` — current branch
- `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no-upstream"` — upstream tracking
- `git log --oneline <base>..HEAD` — commits that will be in the MR (use the default branch name from the first command)

Abort with an explanation if:
- Current branch *is* the default branch — refuse to open an MR from `main` into `main`. Tell the user to switch to a feature branch first.
- There are zero commits ahead of the base branch — nothing to MR.

## Step 3 — Push the branch

- If the branch has no upstream: `git push -u origin <current-branch>`
- If it has an upstream and is ahead of remote: `git push`
- If it is up to date with the remote: skip
- Never force-push. If the push is rejected as non-fast-forward, stop and ask the user how to proceed (do not pass `--force` or `--force-with-lease` on your own).

## Step 4 — Draft the MR title and body

Inspect ALL commits in the MR range, not just the latest:
- `git log <base>..HEAD` for commit messages
- `git diff <base>...HEAD --stat` for the file-level shape of the change

Write an MR title and body following this repo's conventions (peek at recent merged MRs with `glab mr list --state merged --per-page 5` if you need a style reference):
- **Title:** under 70 characters, imperative mood, summarizes the whole branch (not just the last commit).
- **Body:** use the standard format below. Keep it tight — bullets, not paragraphs.

```markdown
## Summary
- <1-3 bullets covering what changed and why>

## Test plan
- [ ] <bulleted checklist of what was verified or still needs verifying>
```

Do not append trailers, signatures, or "Generated with" lines.

## Step 5 — Create the MR

Run:

```
glab mr create \
  --target-branch <default-branch> \
  --source-branch <current-branch> \
  --title "<title>" \
  --description "$(cat <<'EOF'
<body>
EOF
)" \
  --yes
```

Pass the description via HEREDOC to preserve formatting. `--yes` skips non-essential interactive prompts (it does not bypass auth).

Do NOT pass any of these unless the user explicitly asked for them:
- `--draft`
- `--squash-before-merge`
- `--remove-source-branch`
- `--assignee` / `--reviewer`
- `--label` / `--milestone`

## Step 6 — Report

Print the MR URL returned by `glab mr create` so the user can click it. Do not auto-merge, do not assign reviewers, do not add labels — leave those decisions to the user.

## Notes
- If `glab` is not installed, stop and tell the user to run `brew install glab`.
- If `glab auth status` shows the user is not authenticated, stop and tell them to run `glab auth login` via the `!` prefix in the prompt — it is interactive (browser/token flow) and must run in their terminal, not inside a tool call.
- If the repo's `origin` does not point at GitLab, stop and ask the user whether they meant to use `/cpr` (GitHub) instead.
- If the repo has multiple remotes and `origin` is not the GitLab one, ask before proceeding rather than guessing.
- If the working directory is a git worktree, everything above still applies — the worktree's branch is what gets pushed. Do not switch to the main worktree, do not delete the worktree, do not clean up the branch. The user manages worktree lifecycle separately.
