---
name: merge-mr
description: Merge the current branch's GitLab MR after verifying all review discussions are resolved.
---

Merge gate for the current branch's MR on GitLab. Verifies that the review process is complete before merging.

## Step 1 — Identify the MR

Run these in parallel:
- `glab mr list --source-branch=$(git branch --show-current) -F json` — find the MR
- `glab repo view -F json | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])"` — project ID

Extract `iid` and `web_url`.

Abort if no MR found for the current branch.

## Step 2 — Pre-merge checks

Run these in parallel:

### Check 1: All discussions resolved
```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions"
```
Parse the response. Count discussions where any note has `resolvable: true` and `resolved: false`. If any unresolved discussions exist, list them and abort.

### Check 2: Review complete marker
```bash
glab api "projects/<project-id>/merge_requests/<iid>/notes?sort=desc&per_page=20"
```
Look for a note containing "Review Complete" or "Ready for merge" in the recent notes. If no review summary exists, warn the user that no review has been performed and ask if they want to proceed anyway.

### Check 3: Branch is up to date
```bash
git fetch origin <target-branch>
git log HEAD..origin/<target-branch> --oneline
```
If the target branch has commits not in this branch, warn about potential merge conflicts and suggest rebasing first.

## Step 3 — Merge

Print a pre-merge summary:
- MR title and URL
- Number of commits
- Number of review findings that were addressed
- Whether any checks had warnings

If all pre-merge checks pass (no unresolved discussions, review marker exists,
branch up to date), merge immediately:

```bash
glab mr merge <iid> --squash --remove-source-branch --yes
```

If any check failed, **do not merge**. Print the failures and stop.

If the merge command fails (conflicts, pipeline requirements, etc.), report the
error and stop.

## Step 4 — Clean up

After successful merge, detect whether we are in a worktree or the main repo:

```bash
# Returns the path to the main repo's .git dir, or the .git dir itself
main_git_dir=$(git rev-parse --git-common-dir)
current_toplevel=$(git rev-parse --show-toplevel)
main_toplevel=$(cd "$main_git_dir/.." && pwd)
```

### If running inside a worktree (`current_toplevel != main_toplevel`):

The worktree was created for this review and is no longer needed.

1. Print the merge confirmation with the MR URL.
2. Print cleanup instructions for the user to run after exiting this session:
   ```
   ── Worktree cleanup ────────────────────────────────────────
   This review worktree is no longer needed. After exiting this
   Claude Code session, run:

     cd <main_toplevel>
     git worktree remove <current_toplevel>
     git pull

   Or stay in this session and the worktree will be cleaned up
   when you exit — it is safe to close this tmux window.
   ────────────────────────────────────────────────────────────
   ```
3. Do NOT attempt to `cd` out of the worktree or remove it from within — the
   session's working directory is inside the worktree, and removing it would
   break the shell.

### If running in the main repo (not a worktree):

1. Switch to the target branch: `git checkout <target-branch>`
2. Pull the merged changes: `git pull`
3. Delete the local branch if it still exists: `git branch -d <source-branch>`
4. Print the merge confirmation with the MR URL.

## Notes
- This skill exists as a convenience — merging via the GitLab web UI or `glab mr merge` directly is equally valid.
- The `--remove-source-branch` flag deletes the remote branch after merge. If the user wants to keep it, they should merge via the web UI.
- Never force-merge or bypass discussion resolution requirements.
- If the user explicitly wants to merge without review, they can use `glab mr merge` directly — this skill intentionally gates on the review process.
- **Worktree lifecycle:** The reviewer creates the worktree before starting, and
  removes it after the MR is merged and the session ends. `/merge-mr` reminds
  the user to clean up but does not remove the worktree itself — the shell's
  working directory is inside it.
