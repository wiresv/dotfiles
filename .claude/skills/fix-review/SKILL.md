---
name: fix-review
description: Read unresolved review findings from the current branch's GitLab MR, fix the code, push, resolve discussions, and re-review.
---

Iterative fix loop: read review findings posted on the current branch's MR, fix each one, push the fixes, resolve the discussions, and re-review. Repeats up to 3 iterations until convergence.

## Step 1 — Identify the MR

Run these in parallel:
- `glab mr list --source-branch=$(git branch --show-current) -F json` — find the MR
- `glab repo view -F json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'], d['default_branch'])"` — project ID and target branch

Extract `iid` and `project_id`.

Abort if no MR found for the current branch.

## Step 2 — Fetch unresolved discussions

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions"
```

Parse the JSON response. For each discussion:
- Check if it has `notes` where any note's `resolvable` is `true` and `resolved` is `false`
- Filter to review-generated discussions by looking for the severity prefix pattern: `**[Critical]**`, `**[Warning]**`, or `**[Suggestion]**` in the first note's body
- Extract:
  - `discussion_id` (the discussion's `id`)
  - `note_id` (the first note's `id`, needed for resolution)
  - Severity level
  - The finding description
  - File path and line number (from `position.new_path` and `position.new_line` if present)

If there are no unresolved review discussions, post a "Ready for merge" summary and stop (skip to Step 7).

## Step 3 — Triage findings

Sort findings by severity: Critical first, then Warning, then Suggestion.

For each finding, determine if it is actionable:
- **Actionable:** The finding describes a specific code change that can be made (fix a bug, add a type, add validation, etc.)
- **Not actionable:** The finding is a question, a style preference without a clear fix, or requires architectural decisions beyond this MR's scope

For non-actionable findings, reply to the discussion explaining why it cannot be auto-fixed, but do NOT resolve it — leave it for the developer to decide.

## Step 4 — Fix each actionable finding

For each actionable finding:

1. **Read the relevant file(s)** — understand the full context, not just the line mentioned
2. **Make the fix** — edit the code to address the finding
3. **Verify locally:**
   - Run `composer phpstan 2>&1 | grep -E "(ERROR|FOUND)" | head -20` to check for type errors
   - Run `composer phpcs 2>&1 | grep -E "(ERROR|WARNING)" | head -10` to check style
   - If the fix introduced new issues, adjust until clean

Track which discussions were addressed and which files were modified.

## Step 5 — Commit and push

Stage only the files that were modified for fixes (no `git add .`):

```bash
git add <file1> <file2> ...
```

Commit with a conventional message referencing the iteration:

```bash
git commit --trailer "Assisted-by: Claude Code" -m "$(cat <<'EOF'
fix: address review findings (iteration N)
EOF
)"
```

Where N is the current iteration number (1, 2, or 3).

Push:

```bash
git push
```

If the push fails (non-fast-forward), stop and ask the user. Never force-push.

## Step 6 — Resolve addressed discussions

For each discussion that was successfully addressed, resolve it:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions/<discussion_id>" \
  -X PUT \
  -f "resolved=true"
```

Before resolving, post a reply note on the discussion explaining what was fixed:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions/<discussion_id>/notes" \
  -X POST \
  -f "body=Fixed in commit <short-sha>: <brief description of fix>"
```

## Step 7 — Re-review or converge

After fixing and resolving, check the state:

1. **Count remaining unresolved discussions** (re-fetch from API to confirm)
2. **Check iteration count**

### If iteration < 3 and there are resolved findings:
Run an incremental review — only review the new diff since the last review:
- `git diff <previous-head-sha>...HEAD` — just the fix commits
- Look for issues introduced by the fixes themselves
- Post any new findings as new discussions (same format as `/review-mr`)
- If new findings were posted, increment iteration and go back to Step 2

### If iteration >= 3 and unresolved discussions remain:
Post a summary and stop:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/notes" \
  -X POST \
  -f "body=## Fix-Review Summary (iteration 3 — manual review needed)

Addressed **X** of **Y** findings across 3 iterations. **Z** findings remain unresolved and require manual attention.

Remaining issues:
- [ ] Finding 1 description
- [ ] Finding 2 description

_Please review the remaining items manually before merging._"
```

### If all discussions are resolved and no new findings:
Post a convergence summary:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/notes" \
  -X POST \
  -f "body=## Review Complete ✓

All **X** findings addressed across **N** iteration(s). All discussions resolved.

**Ready for merge.** Run \`/merge-mr\` or merge manually via \`glab mr merge <iid> --squash\`."
```

## Step 8 — Report

Print:
- How many findings were addressed vs. remaining
- Which iteration this was
- Whether the MR is ready for merge
- Next action: merge, or manual review needed

## Notes

- **Iteration tracking:** Keep a mental count of iterations within this invocation. If `/fix-review` is called multiple times manually, each call is iteration 1 — the cap prevents runaway within a single invocation.
- **Never resolve discussions you didn't fix.** Only resolve a discussion when you have committed a code change that addresses it.
- **Don't fix Suggestions unless they're trivial.** Focus on Critical and Warning findings. Mention Suggestions in the summary but don't burn iterations on them unless you can fix them in passing.
- **Pre-commit hooks may modify files.** If `git commit` triggers phpcbf or other auto-fixers, include those changes in the commit. Do not use `--no-verify`.
- **If PHPStan or PHPCS fail after fixes**, fix the new issues before committing. The goal is to leave the codebase in a better state, not introduce regressions.
- **Cost awareness:** Each iteration involves a review pass. For large diffs, prefer fixing all findings in one batch rather than one-at-a-time commits.
