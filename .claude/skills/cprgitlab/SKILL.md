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

## Step 2.5 — Ensure a descriptive branch name

Claude Code worktrees generate random branch names (e.g., `worktree-mighty-sprouting-honey`) that are meaningless in MR history. Detect and fix these before pushing.

**When to rename:** if the current branch name matches any of these patterns:
- Starts with `worktree-`
- Matches the three-word `<adjective>-<gerund>-<noun>` pattern typical of auto-generated worktree names (e.g., `quizzical-juggling-swan`, `resilient-wobbling-glacier`)
- Is otherwise clearly non-descriptive of the actual changes

**How to rename:**
1. Analyze the commits in the MR range (`git log <base>..HEAD` and `git diff <base>...HEAD --stat`) to understand what changed.
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

## Step 6 — Report and spawn review agent

Print the MR URL returned by `glab mr create` so the user can click it.

Then **switch back to the default branch** so the feature branch is free for
the review agent's worktree:

```bash
git checkout <default-branch>
```

### Spawn the autonomous review agent

Use the `Agent` tool to spawn an independent reviewer in an isolated worktree.
This is **mandatory** — do not skip it, do not run `/review-mr` yourself.

```
Agent({
  name: "MR-<iid>-reviewer",
  description: "Review MR !<iid>",
  isolation: "worktree",
  run_in_background: true,
  prompt: <see below>
})
```

**The agent prompt must be self-contained** — the subagent has zero memory of
this session. Include all of these values (filled in from the MR you just
created):

```
You are an independent code reviewer. Review, fix, and merge MR !{iid}.

## Setup
- Branch: {branch_name}
- Target: {default_branch}
- MR URL: {mr_url}
- Project ID: {project_id} (get via: glab repo view -F json | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")

1. Check out the branch: git checkout {branch_name}
2. Read CLAUDE.md for the project's coding standards — every finding must be
   grounded in those standards.

## Review (Step 2)
3. Get the full diff: git diff {default_branch}...HEAD
4. Get the file overview: git diff {default_branch}...HEAD --stat
5. Read every changed file IN FULL (not just diff hunks) to understand context.
6. Review against these categories:
   a. Architecture & Design (CLAUDE.md patterns, PSR-4, dependency injection)
   b. Type Safety (strict_types, native types, no mixed, enums over constants)
   c. Security — CRITICAL for this medical records system:
      - SQL injection (must use QueryUtils with parameterized values)
      - XSS (output escaped with attr(), text(), xlt(), xla())
      - No direct superglobal access ($_GET, $_POST, $_SESSION, $GLOBALS)
      - No patient data (PHI) in log messages
      - Exception messages not exposed to users
      - CSRF protection for state-changing endpoints
      - Authorization checks for protected operations
   d. Error Handling (catch \Throwable, PSR-3 context arrays, no catch-and-silence)
   e. Testing (new paths covered, data providers have @codeCoverageIgnore)
   f. PHPStan L10 compliance (no @var casts, no new baseline entries)
   g. Style (conventional commits, file headers, 4-space indent)
7. Parse the MR description's Test Plan items. Verify EVERY item:
   - Verified: mark it [x] via glab api PUT on the MR description
   - Failed: post a [Warning] discussion explaining what failed
   - Cannot verify: post a note explaining why

## Post findings (Step 3)
8. For each finding, post an MR discussion via:
   glab api "projects/{project_id}/merge_requests/{iid}/discussions" -X POST -f "body=..."
   Prefix with severity: **[Critical]**, **[Warning]**, or **[Suggestion]**
   Include: what's wrong, why it matters, and the suggested fix.
9. Post a summary note with finding counts.

## Fix (Step 4) — only if there are findings
10. Fetch unresolved discussions from the MR.
11. For each actionable finding: read the file, make the fix, verify locally.
12. Stage specific files (no git add .), commit: fix: address review findings (iteration N)
13. Push: git push
14. Resolve each addressed discussion via:
    glab api "projects/{project_id}/merge_requests/{iid}/discussions/{discussion_id}" -X PUT -f "resolved=true"
15. Re-review the fix diff. Repeat up to 3 iterations.

## Merge (Step 5) — only when all discussions are resolved
16. Verify: all discussions resolved AND no new findings on latest diff.
17. Merge: glab mr merge {iid} --squash --remove-source-branch --yes
18. Post final summary: how many findings addressed, iterations taken.

## Rules
- Never fabricate findings. Zero findings is a valid outcome.
- Focus on what linters CANNOT catch: logic errors, security design, HIPAA gaps.
- For docs-only diffs, abbreviate code review but ALWAYS verify test plan items.
- Do not fix [Suggestion] items unless trivial. Focus on [Critical] and [Warning].
- If after 3 iterations unresolved findings remain, post a summary and stop WITHOUT merging.
```

After spawning the agent, print:

```
Review agent spawned for MR !<iid> in background worktree.
You will be notified when the review-fix-merge cycle completes.
```

**Do NOT run `/review-mr` yourself.** Do NOT wait for the agent to complete.
Your job as the authoring session ends here — continue with other work.

## Notes
- If `glab` is not installed, stop and tell the user to run `brew install glab`.
- If `glab auth status` shows the user is not authenticated, stop and tell them to run `glab auth login` via the `!` prefix in the prompt — it is interactive (browser/token flow) and must run in their terminal, not inside a tool call.
- If the repo's `origin` does not point at GitLab, stop and ask the user whether they meant to use `/cpr` (GitHub) instead.
- If the repo has multiple remotes and `origin` is not the GitLab one, ask before proceeding rather than guessing.
- If the working directory is a git worktree, everything above still applies — the worktree's branch is what gets pushed. Do not switch to the main worktree, do not delete the worktree, do not clean up the branch. The user manages worktree lifecycle separately.
- **Review agent isolation:** The `Agent` tool creates a subagent with a
  completely fresh context window — it receives only the prompt, zero
  conversation history from this session. Combined with `isolation: "worktree"`,
  the reviewer operates on an independent copy of the repo. This is
  architecturally guaranteed to prevent confirmation bias.
