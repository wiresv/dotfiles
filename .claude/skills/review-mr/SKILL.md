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

Run these in parallel:
- `git diff <target>...HEAD` — the full diff that will be reviewed
- `git diff <target>...HEAD --stat` — file-level overview
- `git log --oneline <target>..HEAD` — commits in the MR

Also extract the MR description from the JSON obtained in Step 1. Parse the
**Test plan** section — these are verification tasks that the MR author committed
to. The review must address every test plan item (see Step 3h).

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
The MR description contains a **Test plan** section with checklist items. These
are promises the author made about what would be verified. The reviewer MUST
work through every item:

1. **Parse** each `- [ ]` item from the MR description.
2. **Verify** each item by actually performing the check — read files, run
   commands, cross-reference code. Do not assume items are satisfied; prove it.
3. **Classify** each item:
   - **Verified** — the check passes. Update the MR description to mark it
     `- [x]` via `glab api "projects/<id>/merge_requests/<iid>" -X PUT -f "description=..."`.
   - **Failed** — the check does not pass. Post a `[Warning]` discussion
     explaining what failed and how to fix it.
   - **Cannot verify** — the check requires manual/browser testing or external
     access the reviewer does not have. Post a general note explaining what
     could not be verified and why, so the author knows to check manually.
4. Never leave test plan items unchecked without explanation.

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
- For docs-only diffs, the code review categories (3a–3g) can be abbreviated, but the test plan (3h) and a summary (Step 5) are still mandatory.
- **Parallel security audit:** When spawned from `/cprgitlab`, a separate
  security agent runs `/security-audit-mr` in parallel. Both agents post
  to the same MR. Duplicate findings on the same line are acceptable —
  `/fix-review` fixes the code once and resolves all discussions for that line.
  Do not wait for or coordinate with the security agent.
- Never fabricate findings. If the code is clean, say so. A review with zero findings is a valid outcome.
