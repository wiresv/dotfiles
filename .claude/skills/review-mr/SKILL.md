---
name: review-mr
description: Deep code review of the current branch's GitLab MR. Posts findings as MR discussions with severity levels.
---

Perform a thorough code review of the current branch's merge request on GitLab. Post findings as MR discussion threads so they block merging until resolved.

If no MR exists for the current branch, stop and tell the user to run `/cprgitlab` first.

## Prerequisites — Fresh context required

This review **must** run in a context-isolated session. The standard workflow
achieves this automatically: `/cprgitlab` spawns the review agent via the
`Agent` tool with `isolation: "worktree"`, which guarantees:

1. **Fresh context** — the subagent receives only its prompt, zero conversation
   history from the authoring session.
2. **Worktree isolation** — the agent operates on an independent copy of the
   repo in its own git worktree.

If this skill is invoked manually (not via the autonomous agent), verify that
this session did NOT author the code. If it did, **stop immediately**:

> This session authored the code on this branch and cannot objectively review
> it. Run `/cprgitlab` to spawn an independent review agent, or open a new
> Claude Code session manually.

If the user explicitly overrides this, proceed but post a disclaimer note on
the MR:

> **Note:** This review was performed in the same session that authored the
> code. Findings may be less thorough than an independent review.

### Worktree awareness

This skill typically runs inside a git worktree (created automatically by the
`Agent` tool or manually). Git operations, `glab` commands, and file reads all
work identically in a worktree. Just be aware that:

- `git rev-parse --show-toplevel` returns the worktree path, not the main repo
- The `.git` file in a worktree points back to the main repo's `.git` directory
- `glab` resolves the remote from the worktree's git config, which inherits
  from the main repo — all API calls work as expected

## Step 1 — Identify the MR

Run these in parallel:
- `glab mr list --source-branch=$(git branch --show-current) -F json` — find the MR
- `glab repo view -F json | python3 -c "import json,sys; print(json.load(sys.stdin)['default_branch'])"` — get the target branch
- `git rev-parse --abbrev-ref HEAD` — confirm current branch

Parse the MR JSON to extract:
- `iid` — the MR number
- `web_url` — for reporting
- `diff_refs.base_sha`, `diff_refs.head_sha`, `diff_refs.start_sha` — for inline comments

Abort if:
- No MR found for the current branch
- Current branch is the default branch

## Step 2 — Gather context

The local ref for the default branch is **untrustworthy** in worktree-based
workflows: it often lags `origin/<target>` because the main repo's branch
isn't fast-forwarded between sessions. Diffing against the local ref produces
inflated MR scopes (other people's already-merged commits look like part of
the MR). First refresh the remote-tracking ref, then diff against
`origin/<target>` (never bare `<target>`):

```bash
git fetch origin <target>
```

Then run these in parallel:
- `git diff origin/<target>...HEAD` — the full diff that will be reviewed
- `git diff origin/<target>...HEAD --stat` — file-level overview
- `git log --oneline origin/<target>..HEAD` — commits in the MR

Also extract the MR description from the JSON obtained in Step 1. Parse the
**Test plan** section — these are verification tasks that the MR author committed
to. The review must address every test plan item (see Step 3h) and apply the
**test plan convention** (see "Test plan convention" section below).

### Test plan convention

Every test plan item is one of two kinds. The reviewer classifies each item
**before** doing anything else with it:

1. **Pre-merge gate** (default — no tag). Verifiable from a fresh clone of
   the branch with no external services, no secrets, no deployed
   environment. Examples: `composer phpstan`, `npm run lint:js`, `docker
   compose build <service>`, `composer phpunit-isolated`, `python -m pytest
   tests/unit -m 'not eval'`. The reviewer **runs each one** and ticks
   `[x]` only on green.

2. **Deploy-time gate** (tagged `[deploy-time](LINK)`). Requires real
   secrets, deployed services, external systems, or production data.
   `LINK` must be a URL pointing to the issue tracking the verification.
   The reviewer leaves these unchecked but **edits the MR description in
   place** to append `(verification deferred to <link>)` after the bullet
   so the audit trail is honest.

**Refuse-to-recommend-merge rules** — if any of these fail, the MR is
incomplete and the reviewer must NOT advise merging (and, in the
autonomous flow, must NOT call `glab mr merge`):

- The MR has **zero pre-merge gates.** Push back with a `[Critical]`
  discussion asking the author to add at least one pre-merge gate (build,
  type-check, unit test against fixtures, lint, etc.).
- A `[deploy-time]` item has no tracking link. Post a `[Warning]` asking
  the author to add a link.
- A pre-merge gate failed when run, or could not be run for a reason
  other than environmental (missing tooling on the reviewer's box is
  treated as "could not verify" — see Step 3h — not an MR failure).

Read the project's `CLAUDE.md` to understand coding standards. This is critical — every finding must be grounded in the project's actual conventions, not generic best practices.

## Step 3 — Perform the review

Analyze every changed file in the diff. For each file, read the full file (not just the diff hunks) to understand the surrounding context. Review against these categories:

### 3a. Architecture & Design
- Does the code follow patterns documented in CLAUDE.md?
- Is new code in `/src/` (not `/library/`) with PSR-4 namespacing?
- Are dependencies injected, not pulled from globals or service locators?
- Does it use `QueryUtils` for database access, `OEGlobalsBag` for globals?
- Are value objects `readonly` and `final`?

### 3b. Type Safety
- Does every new file have `declare(strict_types=1)`?
- Are all properties, parameters, and return types natively typed?
- No use of `mixed` where specific types are possible?
- Enums instead of constants for closed sets?
- Array shapes progressing toward DTOs?

### 3c. Security (surface check — deep audit runs in parallel)

A dedicated security agent (`/security-audit-mr`) runs in parallel and performs
deep vulnerability analysis with data-flow tracing, confidence scoring, and
HIPAA-specific checks. This section catches only the most obvious security
issues visible during the general review:

- SQL injection: are all queries via `QueryUtils` with parameterized values?
- XSS: is all output escaped with `attr()`, `text()`, `xlt()`, `xla()`?
- No direct `$_GET`, `$_POST`, `$_SESSION`, `$GLOBALS` access in new code?
- No patient data (PHI) in log messages?

If you spot something beyond these basics, post it — duplicate findings from
the security agent are acceptable. `/fix-review` resolves all related
discussions after fixing the code once.

### 3d. Error Handling
- Catching `\Throwable`, not `\Exception`?
- PSR-3 context arrays for logging (no string interpolation in messages)?
- Exceptions propagated, not caught-and-silenced?
- Proper exception chaining with generic wrapper messages?

### 3e. Testing
- Are new code paths covered by tests?
- Do data providers have `@codeCoverageIgnore`?
- Are Twig template changes covered by render tests?

### 3f. PHPStan Compliance
- Would this code pass PHPStan level 10?
- No inline `@var` casts that could be fixed at the source?
- No new baseline entries needed?

### 3g. Style & Conventions
- Conventional commit messages?
- Proper file headers with author/copyright?
- 4-space indentation, LF line endings?

### 3h. Test Plan Verification (MANDATORY)

The MR description contains a **Test plan** section with checklist items.
Apply the **test plan convention** from Step 2 — first classify, then act.

1. **Parse** each `- [ ]` item from the MR description.
2. **Classify** each item as a pre-merge gate (no tag) or a deploy-time gate
   (tagged `[deploy-time](LINK)`).
3. **Apply the refuse-to-recommend-merge rules** from Step 2 first. If any
   fail, post the appropriate `[Critical]` / `[Warning]` discussion and
   stop the merge path — do not proceed to verification of the remaining
   items in this turn; let the author fix the test plan first.
4. **For each pre-merge gate:** actually run the command or perform the
   check. Do not assume; prove it.
   - **Green** — update the MR description to mark it `- [x]` via
     `glab api "projects/<id>/merge_requests/<iid>" -X PUT -f "description=..."`.
   - **Failed** — post a `[Warning]` discussion explaining what failed and
     how to fix it. Do not tick.
   - **Could not run** (genuinely missing tooling on the reviewer's box,
     not "I didn't try") — post a note naming the tool and why; ask the
     author to verify locally. Do not tick.
5. **For each deploy-time gate:** never run it, but **edit the MR
   description in place** to append `(verification deferred to <link>)` so
   readers immediately see the audit trail without parsing tags. Use the
   same `glab api … PUT description=…` mechanism.
6. Never silently leave a pre-merge item unchecked. Every unchecked
   pre-merge item must have either a `[Warning]` discussion or a
   "could not run" note attached to it.

## Step 4 — Post findings as MR discussions

For each finding, determine its severity:
- **`[Critical]`** — Security vulnerability, data corruption risk, or crash. Must fix before merge.
- **`[Warning]`** — Violates CLAUDE.md conventions, type safety gap, missing test coverage. Should fix.
- **`[Suggestion]`** — Improvement opportunity, readability, minor convention. Nice to have.

### Posting general findings

For findings that span multiple files or are architectural:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions" \
  -X POST \
  -f "body=**[Severity]** Description of the finding.

**Why:** Explanation of why this matters.

**Suggested fix:** What to do about it."
```

### Posting inline findings

For findings tied to specific lines in specific files, use position parameters for inline comments:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions" \
  -X POST \
  -f "body=**[Severity]** Description" \
  -f "position[position_type]=text" \
  -f "position[base_sha]=<base_sha>" \
  -f "position[head_sha]=<head_sha>" \
  -f "position[start_sha]=<start_sha>" \
  -f "position[new_path]=<file_path>" \
  -f "position[new_line]=<line_number>"
```

Use the `diff_refs` from Step 1 for the SHA values. `new_path` is relative to the repo root. `new_line` is the line number in the new version of the file.

If an inline comment fails (e.g., the line is not part of the diff), fall back to a general discussion mentioning the file and line.

### Batch posting

Post findings one at a time. Do not batch — each discussion thread should be independently resolvable.

## Step 5 — Post summary

After all findings are posted, add a summary note:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/notes" \
  -X POST \
  -f "body=## Review Summary

| Severity | Count |
|----------|-------|
| Critical | N |
| Warning  | N |
| Suggestion | N |

**Files reviewed:** N
**Commits reviewed:** N

_Review performed by Claude Code. A parallel security audit (/security-audit-mr) may post additional findings. Run \`/fix-review\` to address findings._"
```

## Step 6 — Report

Print:
- MR URL
- Finding counts by severity
- Whether the MR is blocked (any Critical or Warning findings create unresolved discussions)
- Suggest running `/fix-review` if there are actionable findings

## Notes

- Always get the project ID dynamically: `glab repo view -F json | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])"`
- If `glab api` returns errors for inline comments, fall back to general discussions. Some GitLab CE versions have limitations on position-based comments.
- Do NOT post findings for issues already caught by pre-commit hooks (pure formatting, trailing whitespace) — those are already gated locally.
- Focus the review on things static analysis and linters CANNOT catch: logic errors, architectural violations, security design flaws, missing validation at system boundaries, HIPAA compliance gaps.
- **Always run Step 3h (Test Plan Verification)**, even for docs-only or trivially small diffs. The test plan is a contract — skipping it is a review failure.
- **Rationalizations to refuse:** "I noted in my summary that the items are deploy-time, that's enough" — no, edit the description. "All items are deploy-time but I trust the author" — no, refuse to merge until they add a pre-merge gate. "The MR is small so the test plan rules don't apply" — they apply universally. "I'll mark `[x]` because the code looks like it should pass the gate" — never; only tick what you actually ran.
- **Evaluate gate quality, not just gate exit code.** Run each pre-merge gate and observe what it actually tests. If the command runs green but doesn't actually exercise the invariant the bullet claims (e.g., `grep -F "FILENAME" path/FILENAME` searches file content for a literal string when the bullet's intent was to confirm the file exists at that path; or `split('foo')[0]` truncates earlier than expected because `foo` also appears in comments), post a `[Warning]` discussion explaining the gate is broken even if the underlying claim happens to be true. Validate the underlying claim some other way before ticking — never silently rubber-stamp a gate whose failure mode you couldn't articulate. The repo's CLAUDE.md "Authoring pre-merge gates" subsection has a concrete anti-pattern catalog of bugs to look for.

### Linear hygiene contract (reviewer side)

The author's `/cprgitlab` workflow includes a `Closes TODO-XX` or `Refs TODO-XX` line in the MR body. The reviewer enforces the contract on three checkpoints:

**At review time (Step 3 territory):**

1. Parse the MR description for `Closes TODO-XX` / `Refs TODO-XX` lines.
2. If the diff is non-trivial (more than typo / lint cleanup) and there is **no Linear linkage**, post a `[Warning]` discussion asking the author to file or link an issue. Do not merge until they do.
3. If linkage exists, fetch the referenced issue via the Linear MCP (`mcp__linear-server__get_issue`) and read its description + acceptance criteria. Compare against the actual diff:
   - File paths the issue describes that aren't in the diff → drift; post a `[Warning]` asking the author to update either the issue description or the MR scope.
   - Acceptance criteria the diff doesn't satisfy → drift; same.
   - Issue says "implement X" but MR also includes unrelated work Y → ask the author to either split the MR or file a separate issue for Y.

**At merge time (Step 5 territory) — after `glab mr merge` succeeds:**

For each `Closes TODO-XX` / `Refs TODO-XX` line:

- For `Closes`: mark the issue Done via `mcp__linear-server__save_issue` with `state: "Done"`. Tick acceptance-criteria checkboxes that the merged code satisfies (mutate the issue's description with boxes checked).
- For `Refs`: leave the issue's status as "In Progress" if there's remaining work; post a one-line Linear comment via `mcp__linear-server__save_comment` summarizing what this MR contributed and what remains.
- Either way: post a single Linear comment on the issue with the merge SHA, the MR URL, and a one-line summary. This builds a per-issue audit trail showing every MR that touched it.

**If the merged MR has no Linear linkage** (you flagged it earlier and the author argued it's a true trivial cleanup): merge anyway, but include a one-line note in the MR final summary saying "no Linear linkage; reviewer accepted as trivial cleanup."

**Rationalizations to refuse:**

- "I already noted in my review that the issue should be closed; that's enough." — no, actually mark it Done via the MCP. The audit trail lives in Linear, not in MR comments.
- "The author will close the issue themselves." — they often won't, and Linear drift compounds. The reviewer is the last actor with full context; the responsibility is yours.
- "The acceptance criteria boxes are out of date / wrong." — fix them in the issue description before merging, then tick what's now correct.
- For docs-only diffs, the code review categories (3a–3g) can be abbreviated, but the test plan (3h) and a summary (Step 5) are still mandatory.
- **Parallel security audit:** When spawned from `/cprgitlab`, a separate
  security agent runs `/security-audit-mr` in parallel. Both agents post
  to the same MR. Duplicate findings on the same line are acceptable —
  `/fix-review` fixes the code once and resolves all discussions for that line.
  Do not wait for or coordinate with the security agent.
- Never fabricate findings. If the code is clean, say so. A review with zero findings is a valid outcome.
