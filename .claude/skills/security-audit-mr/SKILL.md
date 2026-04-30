---
name: security-audit-mr
description: Deep security audit of the current branch's GitLab MR. Posts findings as MR discussions with severity levels. Designed to run in parallel with /review-mr.
---

Perform a focused security audit of the current branch's merge request on
GitLab. Post findings as MR discussion threads so they block merging until
resolved.

This skill adapts Anthropic's `/security-review` methodology for GitLab MR
integration. It is **audit-only** — it reads code and posts findings but does
not fix code, push commits, or merge. The `/fix-review` skill handles
remediation.

If no MR exists for the current branch, stop and tell the user to run
`/cprgitlab` first.

## Prerequisites

This audit **must** run in a context-isolated session — either spawned via the
`Agent` tool with `isolation: "worktree"` (the standard path from `/cprgitlab`)
or invoked manually in a fresh Claude Code session.

### Scope

Review **only** security implications of changes newly introduced by this
branch. Do not comment on pre-existing security debt in unchanged code. The
goal is to prevent new vulnerabilities from being introduced, not to audit the
entire codebase.

## Step 1 — Identify the MR

Run these in parallel:
- `glab mr list --source-branch=$(git branch --show-current) -F json` — find the MR
- `glab repo view -F json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'], d['default_branch'])"` — project ID and target branch
- `git rev-parse --abbrev-ref HEAD` — confirm current branch

Parse the MR JSON to extract:
- `iid` — the MR number
- `web_url` — for reporting
- `diff_refs.base_sha`, `diff_refs.head_sha`, `diff_refs.start_sha` — for inline comments

Abort if no MR found or current branch is the default branch.

After identifying the target branch, refresh the remote-tracking ref. The
local ref for the default branch is **untrustworthy** in worktree-based
workflows: it often lags `origin/<target>` because the main repo's branch
isn't fast-forwarded between sessions. Diffing against the local ref produces
an inflated audit scope (other people's already-merged commits look like
they're part of the MR). Run:

```bash
git fetch origin <target>
```

Use `origin/<target>` (not bare `<target>`) in **every** `git diff` and
`git log` call throughout this skill.

## Step 1.5 — Verify the checkout matches the MR head

This step exists because of a real failure mode: the audit's worktree can
silently land on the wrong commit (e.g., on `origin/<target>` instead of the
MR's source branch when the spawning session was detached on master). When
that happens:

- The audit reads master's content, not the fix branch's content.
- All findings, line citations, and "this code is fine" verdicts are about
  the wrong code.
- A false-positive turns into a confusing finding the reviewer must dismiss
  by hand. **A false-negative — the audit clears a buggy fix branch
  because it actually read master — produces a silent merge of broken
  code.** This is the worst outcome on this stack.

**Before doing any analysis, verify your checkout:**

```bash
# 1. Get the MR's head SHA from GitLab (canonical source of truth).
MR_HEAD_SHA=$(glab api "projects/<project-id>/merge_requests/<iid>" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['sha'])")

# 2. Get the local HEAD SHA.
LOCAL_HEAD_SHA=$(git rev-parse HEAD)

# 3. Compare. They must match exactly.
if [ "$MR_HEAD_SHA" != "$LOCAL_HEAD_SHA" ]; then
  echo "AUDIT ABORT: local HEAD ($LOCAL_HEAD_SHA) does not match MR head ($MR_HEAD_SHA)"
  # post the abort summary (see below) and exit non-zero
fi
```

**If the SHAs differ, abort the audit:**

1. **Do NOT post any security findings.** The audit was looking at the
   wrong code; any finding would be about a different commit than the
   reviewer is preparing to merge.
2. Post a summary note explicitly flagging the integrity failure (the
   reviewer reads this and refuses to merge):

   ```bash
   glab api "projects/<project-id>/merge_requests/<iid>/notes" \
     -X POST \
     -f "body=## Security Audit Summary

   **AUDIT INTEGRITY FAILURE — could not analyze this MR.**

   The audit's worktree HEAD did not match the MR's head SHA:
   - Expected (MR head): \`$MR_HEAD_SHA\`
   - Actual (local HEAD): \`$LOCAL_HEAD_SHA\`

   This means any analysis would have been against the wrong code. The audit
   has been aborted with **zero findings posted** to prevent a misleading
   summary. The reviewer must refuse to merge this MR until a fresh audit
   runs against the correct commit.

   Likely cause: the spawning session's worktree was detached on a different
   commit when the agent was spawned, and the agent's \`git checkout
   <source-branch>\` either failed silently or did not produce the expected
   tree.

   _Audit performed by Claude Code (\`/security-audit-mr\`)._"
   ```

3. Exit. Do not proceed to Steps 2 onward.

The reviewer's runbook (in `~/.claude/skills/cprgitlab/SKILL.md`) has the
matching counterpart: when the reviewer reads the audit summary and sees
"AUDIT INTEGRITY FAILURE", it refuses to merge and surfaces the issue for
manual investigation.

**Belt-and-suspenders:** the reviewer also performs the same SHA check at
its own startup; both halves of the contract independently verify their
checkouts. A single audit-side check can fail silently if the audit agent
itself is buggy; both sides checking gives true defense in depth.

If the SHAs match, proceed to Step 2 normally. **Always include the audited
SHA in the final summary note** (Step 10) so the reviewer has a paper
trail.

## Step 2 — Early exit for non-code changes

Run `git diff origin/<target>...HEAD --name-only` and check the file extensions.

If the diff contains **only** documentation files (`.md`, `.txt`, `.rst`,
`.adoc`) and no code files (`.php`, `.js`, `.ts`, `.twig`, `.html`, `.sql`,
`.sh`, `.py`), post a summary note and exit:

```
## Security Audit Summary

No code changes to audit — diff contains only documentation files.

_Security audit performed by Claude Code (/security-audit-mr)._
```

Otherwise, continue.

## Step 3 — Gather diff context

Run these in parallel:
- `git diff origin/<target>...HEAD` — full diff
- `git diff origin/<target>...HEAD --stat` — file overview
- Read `CLAUDE.md` for the project's security-related conventions

## Step 4 — Repository security baseline (Phase 1)

Before analyzing the diff, understand the project's existing security patterns.
Run these greps in parallel (limit each to 20 results):

```bash
# Sanitization patterns
grep -r "QueryUtils\|sqlStatementThrowException" src/ --include="*.php" -l | head -20

# Output escaping
grep -r "attr(\|text(\|xlt(\|xla(" src/ --include="*.php" -l | head -20

# Auth and access control
grep -r "AclMain\|aclCheckCore\|checkAcl\|isAuthenticated\|SessionUtil" src/ --include="*.php" -l | head -20

# CSRF protection
grep -r "CsrfUtils\|verifyCsrfToken" src/ --include="*.php" -l | head -20

# Crypto usage
grep -r "openssl_\|sodium_\|password_hash\|password_verify\|random_bytes\|random_int" src/ --include="*.php" -l | head -20
```

Read 2-3 exemplar files from the results to establish the project's security
baseline — how it parameterizes queries, how it escapes output, how it checks
ACLs, how it validates CSRF tokens. This baseline is what you compare new code
against in the next phase.

## Step 5 — Comparative analysis (Phase 2)

For each changed file in the diff:
1. Read the **full file** (not just diff hunks) to understand surrounding context
2. Compare new code against the security patterns established in Step 4
3. Flag any deviation: new database access that doesn't use `QueryUtils`, new
   output that doesn't use `attr()`/`text()`, new endpoints without ACL checks,
   state-changing operations without CSRF verification

## Step 6 — Vulnerability assessment (Phase 3)

Analyze every changed file against these six categories. For each potential
finding, trace the data flow from input to sensitive operation.

### 6a. Input Validation
- **SQL injection:** Trace every database query in changed code. Must use
  `QueryUtils` with parameterized values. Flag any string concatenation or
  interpolation into SQL strings.
- **Command injection:** `exec()`, `system()`, `shell_exec()`, `proc_open()`,
  `passthru()`, backtick operators — flag if any argument incorporates
  user-controlled input without validation.
- **XXE injection:** `simplexml_load_string()`, `DOMDocument::loadXML()` on
  user-supplied XML without disabling external entities.
- **Template injection:** Twig `raw` filter or Smarty `{$var nofilter}` on
  user-controlled data. Dynamic template loading from user input.
- **Path traversal:** `file_get_contents()`, `fopen()`, `include`/`require`
  where the path incorporates user input without `realpath()` + base-directory
  validation.

### 6b. Authentication and Authorization
- New endpoints or routes missing `AclMain::aclCheckCore()` or equivalent
  ACL checks.
- Session management: improper session ID regeneration after privilege change,
  session fixation vectors.
- **CSRF:** State-changing endpoints (POST/PUT/DELETE handlers) without
  `CsrfUtils::verifyCsrfToken()`.
- **Privilege escalation:** Operations accessing resources belonging to other
  users or patients without ownership verification.
- JWT handling (if applicable): algorithm confusion, missing signature
  validation.

### 6c. Cryptography and Secrets
- Hardcoded API keys, passwords, tokens, or database credentials in code
  (should be in `.env`, Secrets Manager, or SSM Parameter Store).
- Weak algorithms: MD5/SHA1 for password hashing (must use `password_hash()`
  with `PASSWORD_ARGON2ID` or `PASSWORD_BCRYPT`), DES/RC4 for encryption.
- Insecure randomness: `rand()`, `mt_rand()`, `uniqid()` used where
  `random_bytes()` or `random_int()` is needed for security-sensitive values
  (tokens, session IDs, nonces).
- Certificate validation bypass: `CURLOPT_SSL_VERIFYPEER => false` or
  `verify_peer => false` in stream contexts.

### 6d. Injection and Code Execution
- `eval()`, `assert()` (string mode), `preg_replace()` with `/e` modifier,
  `create_function()`.
- **Deserialization:** `unserialize()` with user-controlled input (must use
  `json_decode()` or `unserialize()` with `allowed_classes`).
- **XSS (reflected):** User input rendered in HTML/JS without escaping through
  `attr()`, `text()`, `xlt()`, `xla()`.
- **XSS (stored):** User input saved to database and rendered later without
  escaping. Check Twig templates for `|raw` filter on database-sourced data.

### 6e. Data Exposure (HIPAA-critical)
- **PHI in logs:** Any of the 18 HIPAA identifiers (patient name, DOB, SSN,
  diagnosis, medications, medical record number, etc.) appearing in
  `$this->logger->*()` calls, `error_log()`, or exception messages.
- **PHI in URLs:** Patient identifiers in GET parameters (appear in server
  logs, browser history, referrer headers).
- **Debug information:** `var_dump()`, `print_r()`, `debug_backtrace()` in
  non-test code.
- **API over-fetching:** Endpoints returning more patient data fields than the
  consumer needs.
- **Error message exposure:** `$e->getMessage()` in HTTP responses or rendered
  templates (may contain SQL, file paths, internal details).

### 6f. OpenEMR-Specific
- **Audit trail gaps:** Operations that modify patient data without going
  through the auditable service layer.
- **Access logging:** New patient data access points that bypass the existing
  access logging mechanism.
- **Minimum necessary rule:** New queries that `SELECT *` from patient tables
  rather than selecting specific needed columns.
- **Security infrastructure changes:** If the diff modifies `QueryUtils`,
  `CsrfUtils`, `AclMain`, `SessionUtil`, or any file in `src/Common/Auth/`
  or `src/Common/Csrf/`, escalate — grep for all callers of changed functions
  and verify the change does not weaken existing security guarantees.

### 6g. Functional defects in security primitives (fail-closed bugs)

This category exists because of a real recurrence: the audit's docs-research
phase often surfaces a discrepancy between the code and the canonical
reference (AWS Service Authorization Reference, RFC, vendor SDK contract)
where the code is **broken in a way that fails closed** — the security
primitive doesn't actually function, but the failure mode is
denial-of-service or denial-of-feature, not exploitable permission widening.
Historically these were buried in a "note for the parent agent" inside the
summary, missed by the reviewer, and surfaced only as post-merge follow-up
MRs. That pattern is no longer acceptable.

**A finding belongs in this category when ALL of the following hold:**
1. The audit's research against an authoritative external reference
   established a discrepancy between code and documented behavior.
2. The discrepancy concerns a security primitive (IAM condition key, ACL
   check, signature verification, TLS verification flag, crypto mode
   parameter, OAuth scope, JWT claim, condition operator, etc.).
3. The runtime effect is functional breakage of that primitive — the
   primitive denies legitimate requests, rejects valid signatures, fails to
   match the resource it should match. **Crucially: the failure mode is
   fail-closed, not fail-open.** A fail-open functional defect is a HIGH
   security finding and goes in the appropriate prior category (auth bypass
   under 6b, signature bypass under 6c, etc.).

**Examples that fit:**
- IAM condition key namespace mismatch (`ec2:ResourceTag/` used on an
  `ssm:` action where only `aws:ResourceTag/` is honored — IAM treats the
  unknown key as unmet, denies every legitimate call).
- An ACL check function that always returns `false` because of a typo in
  the role name lookup.
- A JWT validator that rejects every well-formed token because the audience
  check uses string equality on a base64 value vs. its decoded form.
- TLS pinning code that mismatches every cert because the pin is computed
  from the leaf cert but compared against the intermediate.

**Examples that do NOT fit (handle elsewhere):**
- A typo that makes an ACL check always return `true` → 6b auth bypass,
  HIGH.
- A signature verifier that accepts any signature → 6c crypto, HIGH.
- A code style issue or maintainability concern → not a security finding,
  do not surface.

**Severity and posting:** these findings are **MEDIUM severity, posted as
`[Warning]` discussions on the MR** at the standard >= 0.7 confidence
threshold. They do NOT bypass the confidence and exclusion gates above.
What changes is the *channel*: a 6g finding is a discussion, not a
summary side-note. The author/reviewer fix loop addresses it on the same
MR before merge. The audit summary may reference it but must not be the
only place it appears.

**Rule of thumb:** if you find yourself writing "worth surfacing to
`/review-mr`" or "for the parent agent's attention" or "should flag in
review", you are looking at a 6g finding — post it as a discussion, not a
summary footnote.

## Step 7 — Confidence scoring and filtering

For each potential finding from Step 6, assign a confidence score:

| Score | Meaning | Action |
|-------|---------|--------|
| 0.9-1.0 | Certain exploit path identified | Report as `[Critical]` |
| 0.8-0.9 | Clear vulnerability pattern with known exploitation | Report as `[Critical]` (HIGH) or `[Warning]` (MEDIUM) |
| 0.7-0.8 | Suspicious pattern requiring specific conditions | Report as `[Warning]` |
| Below 0.7 | Too speculative | **Do not report** |

**Severity mapping:**

| Security Severity | Confidence | MR Discussion |
|-------------------|------------|---------------|
| HIGH (directly exploitable — RCE, data breach, auth bypass) | >= 0.8 | `**[Critical]**` |
| HIGH | 0.7-0.8 | `**[Warning]**` |
| MEDIUM (requires specific conditions but significant impact) | >= 0.7 | `**[Warning]**` |
| LOW | any | Do not report |

**Never report LOW severity findings.** Only HIGH and MEDIUM with sufficient
confidence.

## Step 8 — Apply hard exclusions

Before posting, discard any finding that matches these exclusions:

1. DoS / resource exhaustion
2. Secrets stored on disk (handled by separate processes)
3. Rate limiting concerns
4. Memory / CPU exhaustion
5. Missing input validation on non-security-critical fields without proven
   security impact
6. Lack of hardening (only flag concrete vulnerabilities, not missing best
   practices)
7. Theoretical race conditions without a concrete exploit path
8. Outdated third-party library versions (managed by dependency scanning)
9. Test-only files (`tests/` directory)
10. Log spoofing
11. SSRF where the attacker controls only the path (must control host or
    protocol to report)
12. User content in AI system prompts
13. Regex injection / ReDoS
14. Documentation files
15. Missing audit logs (as a standalone finding — flag only when a specific
    patient data operation bypasses existing audit logging)
16. Logging non-PII data (only report logging of secrets, passwords, or HIPAA
    identifiers)
17. Client-side missing auth checks (backend handles authorization)

**Precedent rules (judgment calls):**
- Logging URLs = safe. Logging high-value secrets = vulnerability.
- UUIDs are unguessable — no need to validate as authorization tokens.
- Environment variables and CLI flags are trusted values.
- Resource management issues (connection leaks) are not security findings.
- React/Angular/Twig auto-escape is XSS-safe unless explicitly bypassed
  (`|raw`, `dangerouslySetInnerHTML`).
- Command injection in shell scripts needs a concrete untrusted-input path.

## Step 9 — Post findings as MR discussions

For each finding that passes confidence scoring and exclusion filtering, post
an MR discussion. Use the same format as `/review-mr` for `/fix-review`
compatibility.

### General findings

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions" \
  -X POST \
  -f "body=**[Severity]** Security: <category> — <description>

**Confidence:** <score>/1.0
**Category:** <Input Validation | Auth & Authz | Crypto & Secrets | Injection & Code Exec | Data Exposure / HIPAA | OpenEMR-Specific>

**Exploit scenario:** <how this could be exploited>

**Suggested fix:** <specific remediation>"
```

### Inline findings

For findings tied to specific lines:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/discussions" \
  -X POST \
  -f "body=**[Severity]** Security: <description>" \
  -f "position[position_type]=text" \
  -f "position[base_sha]=<base_sha>" \
  -f "position[head_sha]=<head_sha>" \
  -f "position[start_sha]=<start_sha>" \
  -f "position[new_path]=<file_path>" \
  -f "position[new_line]=<line_number>"
```

If inline posting fails, fall back to a general discussion mentioning the file
and line.

Post findings one at a time — each discussion thread must be independently
resolvable by `/fix-review`.

**No summary side-notes for actionable findings.** Anything you would write
under a "note for the parent agent", "worth surfacing to review", or
similar header inside the audit summary belongs as a discussion instead.
If the finding meets the confidence and severity thresholds (including the
6g category for fail-closed functional defects in security primitives),
post it as a `[Warning]` or `[Critical]` discussion. If it does not meet
the thresholds, do not surface it at all — the reviewer is not a
secondary triage channel for sub-threshold concerns. This rule exists
because side-note findings race with the reviewer's merge timer and
historically arrived too late to act on.

## Step 10 — Post security audit summary

After all findings are posted (or if none were found), post a summary note:

```bash
glab api "projects/<project-id>/merge_requests/<iid>/notes" \
  -X POST \
  -f "body=## Security Audit Summary

**Audited SHA:** \`$LOCAL_HEAD_SHA\` (verified against MR head in Step 1.5)

| Category | Findings |
|----------|----------|
| Input Validation | N |
| Auth & Authz | N |
| Crypto & Secrets | N |
| Injection & Code Exec | N |
| Data Exposure / HIPAA | N |
| OpenEMR-Specific | N |
| Functional defects in security primitives (6g) | N |

**Files audited:** N
**Confidence threshold:** >= 0.7 (findings below this suppressed)
**Hard exclusions applied:** N potential findings filtered

_Security audit performed by Claude Code (/security-audit-mr). Run \`/fix-review\` to address findings._"
```

The review agent checks for this "Security Audit Summary" note before merging.
Always post it, even when there are zero findings.

## Step 11 — Report

Print:
- MR URL
- Finding counts by severity
- Whether the MR is blocked by security findings
- Suggest running `/fix-review` if there are actionable findings

## Notes

- Always get the project ID dynamically: `glab repo view -F json | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])"`
- If `glab api` returns errors for inline comments, fall back to general discussions.
- **Never fabricate findings.** A clean audit with zero findings is a valid and desirable outcome. The confidence threshold and exclusion list exist specifically to prevent false positives.
- **This skill is audit-only.** Do not edit files, do not commit, do not push, do not merge. Post findings and exit. The `/fix-review` skill handles remediation.
- **Parallel operation:** When spawned from `/cprgitlab`, a separate review agent runs `/review-mr` in parallel. Both agents post to the same MR. Duplicate findings on the same issue are acceptable — `/fix-review` resolves all related discussions after fixing the code once.
- Focus on what static analysis tools (PHPStan, PHPCS, Rector) **cannot** catch: logic-level vulnerabilities, authorization design flaws, data flow issues, HIPAA compliance gaps.
