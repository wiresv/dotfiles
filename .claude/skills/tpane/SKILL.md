---
name: tpane
description: "Rename the current tmux window to reflect what this Claude Code session is working on."
---

Rename the current tmux window to a short label that tells the human orchestrator what this session is focused on. Designed for multi-window workflows where 5+ Claude Code sessions run in parallel across worktrees — the label appears in the tmux status bar.

## Steps

1. **Gather context** — run these in parallel:
   - `git rev-parse --abbrev-ref HEAD` — current branch
   - `git log --oneline -3` — recent commits
   - `git diff --stat HEAD~1..HEAD 2>/dev/null` — last commit's shape
   - `git status --short` — uncommitted work

2. **Synthesize a label** from what you know: the branch name, recent commits, any uncommitted work, and the conversation so far. The label must be:
   - **Ultra-short: 15 characters or fewer.** Hard cap, not a target. This appears in the tmux status bar — every character counts. Count the characters before renaming. If it's over 15, cut words, drop articles, abbreviate, or pick a tighter framing — don't ship it long.
   - **Glanceable:** a human scanning 5+ windows should instantly know what this one is doing. Lead with the domain/area, not generic verbs.
   - **No decoration:** no emoji, no brackets, no prefix like "WIP:" or "Claude:". Just the substance.
   - Examples (all ≤15 chars): `CDK infra rules`, `patient API`, `calendar fix`, `phpstan cleanup`, `twig tests`, `kiss skill edit`

3. **Rename the window:**
   ```bash
   tmux rename-window "<label>"
   ```

4. **Report** — print the label you chose so the user can confirm or ask you to change it. One line, nothing else.

## Notes
- If `$TMUX` is empty, we are not in tmux. Say so and stop.
- If the user passes an argument to `/tpane`, use that as the label verbatim instead of generating one.
- If the session is brand new with no git context yet, derive the label from the conversation topic.
