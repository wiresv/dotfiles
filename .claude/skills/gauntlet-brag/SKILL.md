---
name: gauntlet-brag
description: Update ~/gauntlet-brag.md with today's Gauntlet AI progress, framed for promotion / hiring conversations. Run daily or every few days.
---

Append or update today's entry in `~/gauntlet-brag.md` — Austin's running brag document for the Gauntlet AI program. Bias every bullet toward impact, not activity.

The doc tracks two parallel streams:
- **Product work** in `~/code/openemr` (architecture, audits, infra, security disclosures).
- **Force multipliers** — skills authored under `~/.claude/skills` that compound throughout the program.

Program start date: **2026-04-27 (Mon)**. Day numbers count from there. Weeks run Monday → Sunday.

## Pre-flight
- If `~/gauntlet-brag.md` does not exist, bootstrap it (see "Bootstrap" below) and continue.
- Resolve today via `date "+%Y-%m-%d %a %b %-d, %Y"` — never assume the date from conversation context.
- Compute today's day number: `(today - 2026-04-27) + 1`.
- Compute the current week (Mon–Sun); week number = `ceil(day_number / 7)`.

## Steps

1. **Gather signal** — run in parallel:
   - `git -C ~/code/openemr log --since="<today 00:00 or last entry date>" --all --pretty=format:'%h %ad %s' --date=short` — commits across all branches.
   - `git -C ~/code/openemr status --short` and `git -C ~/code/openemr branch --show-current` — in-flight work.
   - `find ~/.claude/skills -maxdepth 2 -name SKILL.md -mtime -1` (single-day) or `-newer <last entry timestamp>` (catch-up) — skills authored or edited in the window.
   - For each new/changed skill, read its frontmatter `description` so the entry can describe leverage gained, not just file names.
   - If `~/code/openemr` is missing or not a git repo, skip the openemr step and warn once.

2. **Detect target section.** Read `~/gauntlet-brag.md`:
   - Find the `## Week N (...)` heading whose date range covers today. If none, insert a new week heading at the top of the weeks list and seed an empty `**Week headline:**` / `**Highlights:**` block.
   - Within that week, find `### Day <N> — <Weekday> <Mon> <D>, <YYYY>` matching today.
     - **Exists** → this is an *update*. Append new bullets to the appropriate subsections; do not delete or reorder existing content.
     - **Does not exist** → this is a *new entry*. Insert at the top of the week's day list (newest-first).

3. **Detect a multi-day gap.** If neither yesterday nor the day before has an entry and today's day number is >2 ahead of the latest existing entry, ask the user (via AskUserQuestion) whether to:
   - (a) only log today, or
   - (b) backfill each missing day one at a time (default).
   When backfilling, walk the days in chronological order, gathering signal scoped to each day.

4. **Draft the entry from signal.** For each day being logged, pre-fill:
   - **Headline:** one line, action verb + outcome ("Shipped …", "Authored …", "Cut …", "Audited …", "Designed …", "Unblocked …").
   - **Shipped (product):** bullets sourced from openemr commits + status. Group related commits into single bullets — don't list every commit verbatim. Each bullet is *what shipped + why it matters*.
   - **Force multipliers (skills / tooling):** bullets for each new/changed skill. Format: `**\`skill-name\`** — <what it automates> (<leverage: time saved, errors prevented, etc.>)`.
   - **Why it matters:** 1–2 bullets connecting the day's work to program goals or career-relevant impact (compounding leverage, milestone progress, demo-able wins).
   - **Tomorrow:** placeholder `<from user>`.

5. **Confirm with the user.** Use `AskUserQuestion` to collect:
   - Headline confirmation or override (offer the draft).
   - Anything not visible in git: pairing, demos, blockers overcome, design conversations, decisions.
   - Tomorrow's next step.
   The user is *editing*, not authoring from scratch.

6. **Write the entry.** Use the `Edit` tool — never rewrite the whole file. Insert the new `### Day N` block at the right anchor, or append bullets to an existing block. Apply phrasing rules:
   - Strong verbs only. No "worked on", "tried to", "started to", "kind of".
   - Force-multiplier bullets state leverage explicitly (e.g. "saves ~N min per MR review", "prevents class of error X").
   - No emoji unless the user requests it.

7. **Refresh the week rollup.** Regenerate the current week's `**Week headline:**` (one line) and `**Highlights:**` (2–4 bullets) from all of that week's daily entries. Replace the existing rollup block in place via `Edit`.

8. **Confirm and stop.** Print one or two sentences: what was added (day number + headline) and the path. Do not commit, do not push, do not touch any repo. The brag doc lives in `~/` and is private.

## Bootstrap

When `~/gauntlet-brag.md` does not exist, create it via `Write` with this skeleton:

```markdown
# Gauntlet AI — Brag Doc
*Austin Wade · started Mon Apr 27, 2026*

> Promotion-style log: what I shipped, why it matters, and the leverage I built.
> Updated via `/gauntlet-brag`. Newest week first; newest day first within each week.

---

## Week 1 (Apr 27 – May 3, 2026)

**Week headline:** _<filled in / refined at week's end>_

**Highlights:**
- _<2–4 bullets pulled from daily entries>_

```

Then proceed with steps 1–8 to add today's entry. If the user has been at it for several days before bootstrapping, offer the multi-day backfill flow from step 3.

## Notes
- The doc is for the user to take to a manager, recruiter, or interviewer. Phrasing matters — every bullet must read well *out of context*.
- Skills count as career artifacts. They are leverage, and they belong in the brag doc, not hidden as tools.
- Do not log secrets, internal credentials, or anything that shouldn't be shown to an interviewer.
- Never commit `~/gauntlet-brag.md` to a repo — it lives in `~/`.
- If the user passes an argument to `/gauntlet-brag` (e.g. `/gauntlet-brag yesterday` or `/gauntlet-brag week`), interpret it: `yesterday` → log yesterday's date instead of today; `week` → refresh the week rollup only without adding a new day.
