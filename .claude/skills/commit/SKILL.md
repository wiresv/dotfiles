---
name: commit
description: Analyze recent git changes, stage them, and commit with a precise message.
---

You are creating a git commit. Follow these steps:

1. Run `git status` and `git diff` (both staged and unstaged) to understand all current changes.
2. Review the actual content of the changes to understand what was done and why.
3. Stage the appropriate files. Use `git add .` unless there is a clear reason to be selective (e.g., unrelated generated files, secrets, or build artifacts that should not be committed).
4. Commit with a single concise message that accurately describes what the changes accomplish.

Commit message rules:
- One line only. No body, no bullet points, no extra paragraphs.
- Focus on the "what" and "why", not the "how".
- Use imperative mood (e.g., "add", "fix", "update", not "added", "fixes", "updated").
- Do NOT append any trailers, signatures, or metadata lines such as "Co-Authored-By", "Signed-off-by", or similar.
- Do NOT pad the message with filler words or generic descriptions. Be specific to the actual changes.

Use a HEREDOC to pass the commit message to `git commit -m`.
