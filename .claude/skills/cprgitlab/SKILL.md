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

The local ref for the default branch is **untrustworthy** in worktree-based
workflows: the main repo's `master` (or `main`) is often left at whatever SHA
was checked out when the worktree was created, while `origin/master` advances
independently as other MRs land. Diffing against the local ref produces
inflated MR scopes (other people's already-merged commits look like they're
part of yours). Use `origin/<base>` everywhere — never bare `<base>`.

First, get the default branch and refresh the remote-tracking ref:
- `glab repo view -F json | jq -r .default_branch` — the MR target name
- `git fetch origin <base>` — refresh `origin/<base>` (substitute `<base>`
  with the name from the previous command)

Then run these in parallel:
- `git rev-parse --abbrev-ref HEAD` — current branch
- `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no-upstream"` — upstream tracking
- `git log --oneline origin/<base>..HEAD` — commits that will be in the MR

Use `origin/<base>` (not bare `<base>`) for **all** downstream diff/log
operations in this skill, and instruct the agent prompts you spawn to do the
same.

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
1. Analyze the commits in the MR range (`git log origin/<base>..HEAD` and `git diff origin/<base>...HEAD --stat`) to understand what changed.
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
- `git log origin/<base>..HEAD` for commit messages
- `git diff origin/<base>...HEAD --stat` for the file-level shape of the change

Write an MR title and body following this repo's conventions (peek at recent merged MRs with `glab mr list --state merged --per-page 5` if you need a style reference):
- **Title:** under 70 characters, imperative mood, summarizes the whole branch (not just the last commit).
- **Body:** use the standard format below. Keep it tight — bullets, not paragraphs.

```markdown
## Summary
- <1-3 bullets covering what changed and why>

## Test plan
- [ ] <pre-merge gate 1 — verifiable from a fresh clone, e.g. build / type-check / unit test>
- [ ] <pre-merge gate 2>
- [ ] [deploy-time](<URL to tracking issue>) <verification that needs real secrets / a deployed service / external system>
```

**Test plan convention** (the reviewer enforces this — the MR will be blocked if you violate it):
- **At least one item must be a pre-merge gate** verifiable from a fresh clone with no external services, no secrets, no deployed env. Examples: `composer phpstan`, `npm run lint:js`, `docker compose build <service>`, `composer phpunit-isolated`, `python -m pytest tests/unit -m 'not eval'`, `python -m compileall <pkg>`, schema validation, lint on changed files. There is *always* something verifiable from the branch alone — even a build or import-check counts.
- **Items requiring real secrets, a deployed service, external systems, or production data** must be tagged `[deploy-time](LINK)` where `LINK` is the issue tracking the verification (typically the Linear deploy issue you should also create at this point). The reviewer will leave these unchecked but annotate the description in place so the audit trail is honest.
- **Common mistake** (do not repeat): writing every item as `curl https://prod/...` or "run eval suite against prod". That MR will get pushed back. If the only thing you can think to test is the live service, add a build / import / unit-fixture gate to the plan as well — and create the deploy tracking issue before opening the MR.
- **Test the test before pasting it.** Bad gates that *false-pass* (return 0 when the invariant doesn't hold) silently let regressions through. Bad gates that *false-fail* erode trust in the convention. For every gate, mentally run it against both an "invariant holds" state and an "invariant violated" state — if you can't picture both, pick a simpler gate. The repo's CLAUDE.md "Authoring pre-merge gates" subsection has a concrete anti-pattern catalog (real bugs from this repo's MR history) and a step-by-step gate-authoring procedure. Read it before authoring test plans for any non-trivial MR. Especially relevant for agent-authored MRs: the most common failure mode is "I wrote what I meant, not what the command does" (e.g. `grep -F "FILENAME" path/FILENAME` searches the *content* for the literal string; `split('foo')[0]` truncates on the first `'foo'` in the file, including in comments).

### Linear hygiene contract (author side)

Every MR that addresses a tracked Linear issue **must** state the linkage in the description, on its own line at the top of the body:

```
Closes TODO-37
```

or, for partial work that doesn't fully close the issue:

```
Refs TODO-37
```

Multiple issues are allowed (one per line). The reviewer parses this to update Linear after merging. **MRs without a Linear linkage are allowed only for trivial cleanup** (typo fixes, lint-only changes); the reviewer will ask why if the diff is non-trivial and unlinked, and you should either link an existing issue or file a new one before continuing.

Before opening the MR, **set the linked issue's status to "In Progress"** via:

```sh
glab api graphql -f query='mutation { issueUpdate(id: "TODO-XX", input: { stateId: "<in-progress-state-id>" }) { success } }'
```

(Or via the Linear MCP if you're authoring through Claude Code.) This signals to anyone watching the queue that the issue is being worked on, not still pending pickup.

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

1. Check out the branch and refresh the remote default-branch ref. The local
   ref for {default_branch} is often stale in worktree-based setups, which
   would inflate the MR scope to include other already-merged commits. Always
   diff against origin/{default_branch}, never against the bare local ref.
       git checkout {branch_name}
       git fetch origin {default_branch}
2. Read CLAUDE.md for the project's coding standards — every finding must be
   grounded in those standards.

## Review (Step 2)
3. Get the full diff: git diff origin/{default_branch}...HEAD
4. Get the file overview: git diff origin/{default_branch}...HEAD --stat
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
7a. **Linear linkage check.** Parse the MR description for `Closes TODO-XX` or `Refs TODO-XX` lines. If the diff is non-trivial (anything beyond pure cleanup / typos / lint) and there is NO linkage, post a [Warning] discussion asking the author to file or link an issue. If the linkage exists, fetch the referenced issue(s) via the Linear MCP / `glab` and check that the MR's actual diff matches what the issue describes. Drift between the issue's "Implementation" / acceptance criteria and the diff → [Warning] with a suggested edit to either the issue or the MR description.

7. Parse the MR description's Test Plan items and apply the test plan convention:
   - Each item is either a **pre-merge gate** (default, no tag — runnable from
     a fresh clone with no external services) or a **deploy-time gate**
     (tagged `[deploy-time](LINK)`).
   - **Refuse-to-merge rules — enforce these BEFORE running any item:**
     - If the test plan has zero pre-merge gates, post a [Critical] discussion
       asking the author to add one (build, type-check, unit test, lint, etc.)
       and DO NOT merge this iteration. Fix-loop will not unblock this — only
       the author can.
     - If a [deploy-time] item has no tracking link, post a [Warning] asking
       the author to add one. DO NOT merge until they do.
   - For each pre-merge gate: actually run it. Verified → mark `[x]` via
     glab api PUT on the MR description. Failed → post [Warning] discussion,
     do not tick. Could not run because of genuinely missing tooling on this
     box → post a note explaining what is missing, do not tick.
   - For each [deploy-time] item: never run it; instead, edit the MR
     description in place to append `(verification deferred to <link>)` after
     the bullet, so anyone reading the MR sees the audit trail without
     decoding tags.
   - Never silently leave a pre-merge item unchecked. Every unchecked
     pre-merge item must have either a [Warning] discussion or a "could not
     run" note attached to it.

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
17. **Test plan gate (refuse-to-merge):** verify all of these before merging:
    - The MR has at least one pre-merge gate.
    - Every pre-merge gate is either ticked `[x]` (because you ran it green)
      or has an attached [Warning] / "could not run" discussion.
    - Every `[deploy-time]` item has a tracking link AND has been annotated
      in the description with `(verification deferred to <link>)`.
    If any of these fail, do NOT merge. Post a [Critical] discussion naming
    the violation and stop.
18. Before merging, check for a "Security Audit Summary" note on the MR
    (glab api "projects/{project_id}/merge_requests/{iid}/notes").
    If absent, wait up to 3 minutes (check every 60s). If still absent,
    proceed but post a note: "Merged without security audit completion.
    Review security findings if they appear post-merge."
19. Merge: glab mr merge {iid} --squash --remove-source-branch --yes
20. **Linear hygiene (post-merge).** For each `Closes TODO-XX` or `Refs TODO-XX` line in the merged MR description:
    - For `Closes`: mark the issue Done via the Linear MCP (`mcp__linear-server__save_issue` with `state: "Done"`). Tick acceptance-criteria checkboxes that the merged code satisfies (mutate the issue's description with the boxes checked).
    - For `Refs`: leave the status as "In Progress" if the issue still has remaining work; post a one-line Linear comment summarizing what this MR contributed and what remains.
    - Either way: post a single Linear comment on the issue with the merge SHA, the MR URL, and a one-line summary of what shipped. Use the Linear MCP `save_comment` if available, or `glab api` for the MR-side cross-link.
21. Post final summary on the MR: how many findings addressed, iterations taken, **and which Linear issues were updated**.

## Rules
- Never fabricate findings. Zero findings is a valid outcome.
- Focus on what linters CANNOT catch: logic errors, security design, HIPAA gaps.
- For docs-only diffs, abbreviate code review but ALWAYS verify test plan items.
- Do not fix [Suggestion] items unless trivial. Focus on [Critical] and [Warning].
- If after 3 iterations unresolved findings remain, post a summary and stop WITHOUT merging.
- **Test plan rationalizations to refuse:**
  - "I noted in my summary that the items are deploy-time, that's enough" — no, edit the description in place.
  - "All items are deploy-time but I trust the author" — no, refuse to merge until they add a pre-merge gate.
  - "The MR is small / docs-only, the test plan rules don't apply" — they apply universally. The author still has to commit to *something* verifiable.
  - "I'll mark `[x]` because the code looks like it should pass the gate" — never; only tick what you actually ran green.
```

### Spawn the security audit agent

Use the `Agent` tool to spawn an independent security auditor in a second
isolated worktree. This runs in parallel with the review agent above.

```
Agent({
  name: "MR-<iid>-security",
  description: "Security audit MR !<iid>",
  isolation: "worktree",
  run_in_background: true,
  prompt: <see below>
})
```

**The security agent prompt must be self-contained** — same principle as the
review agent. Include all MR context values:

```
You are an independent security auditor. Perform a deep security audit of MR !{iid}.

## Setup
- Branch: {branch_name}
- Target: {default_branch}
- MR URL: {mr_url}
- Project ID: {project_id}

1. Check out the branch and refresh the remote default-branch ref. The local
   ref for {default_branch} is often stale in worktree-based setups, which
   would inflate the audit scope to include other already-merged commits.
   The skill instructs you to diff against origin/{default_branch}; honor
   that by always using `origin/<target>` (never bare `<target>`) in any
   `git diff` or `git log` calls.
       git checkout {branch_name}
       git fetch origin {default_branch}
2. Read CLAUDE.md for the project's coding standards and security conventions.
3. Read the security audit methodology from ~/.claude/skills/security-audit-mr/SKILL.md
4. Follow the skill's methodology exactly — all steps from Step 1 onward.

## Context
This is OpenEMR — a medical records system subject to HIPAA. Patient data (PHI)
handling is critical. A general code review agent runs in parallel — your job
is the deep security audit only.

## Key values
- MR iid: {iid}
- Project ID: {project_id}

## Rules
- Only report findings with confidence >= 0.7
- Only HIGH and MEDIUM severity (no LOW)
- Apply all hard exclusions from the skill file
- Post findings as MR discussions with **[Critical]** or **[Warning]** prefix
- Do NOT fix code, push commits, or merge — only audit and report
- Zero findings is a valid outcome. Never fabricate.
```

After spawning both agents, print:

```
Review agent spawned for MR !<iid> in background worktree.
Security audit agent spawned for MR !<iid> in background worktree.
You will be notified when both complete.
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
