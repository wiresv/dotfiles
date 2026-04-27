# Installing this skill

This bundle replaces the existing `design-modern-editorial` skill. The folder layout is identical to the original — `SKILL.md` at the top level, supporting files under `reference/`.

## What changed in this version

The skill was previously oriented around a single canonical reference (`reference/dashboard.html`). Outputs in any medium tended to look like sub-pages of the dashboard because the workflow defaulted to "reproduce, then deviate."

This version inverts that:

- **`SKILL.md` rewritten** so primitives lead, components are optional, and the workflow is "translate, don't transplant."
- **`reference/principles.md` added** — the aesthetic invariants in prose form, used as the grounder when no medium-specific reference fits.
- **Five new reference files added** alongside the dashboard, each demonstrating the same primitives applied to a different medium:
  - `reference/article.html` — long-form writing
  - `reference/marketing.html` — landing page / one-pager
  - `reference/poster.html` — A3 typography poster
  - `reference/slide.html` — 16:9 deck slides
  - `reference/email.html` — narrow-column HTML email
- **`reference/dashboard.html` and `reference/tokens.css`** are unchanged in substance (only a comment in tokens.css is updated to point at the new reference library).

The dashboard is no longer "the canonical reference." It's one example among several, all of equal standing.

## How to install

### Option A — manual swap

1. Locate your current install of the skill. On Cowork / Claude Code with skills enabled, this is typically under one of:
   - macOS: `~/Library/Application Support/Claude/...` (managed by the app)
   - Or wherever your plugin install path is configured.
2. Replace the existing `design-modern-editorial/` folder with the contents of this bundle.
3. Restart Cowork / Claude Code so the skill loader picks up the new files.

### Option B — distribute as a plugin

If you're sharing this with other people, the cleanest format is a zipped folder. The recipient drops `design-modern-editorial/` into their plugins/skills directory using whatever flow they normally use to install plugins. Nothing inside this bundle is machine-specific — all references use relative paths and load fonts from Google Fonts at runtime.

### Option C — install side-by-side under a new name

If you want to compare the two versions, rename this folder to e.g. `design-modern-editorial-v2/` and adjust the `name:` field in the YAML frontmatter at the top of `SKILL.md` to match. Both skills can then coexist, and you can invoke either by name.

## Sanity check

After install, try a few prompts that previously over-replicated and confirm the output now matches the medium:

- "Make a one-page marketing landing page in /design-modern-editorial." → Should NOT have a stat ledger, masthead, or fleuron. Should have one big hero, a lede, three feature cells, a ghost CTA.
- "Make a single deck slide in /design-modern-editorial." → Should NOT have a chart panel, catalog table, or footnotes bar. Should be one big idea per slide with eyebrow + footer chrome.
- "Write me an article in /design-modern-editorial." → Body should be Fraunces (not Geist), should have a drop cap and inline footnotes, should NOT have a ledger or chart.
- "Make a dashboard in /design-modern-editorial." → Should still look exactly like the original `dashboard.html` reference. The dashboard pattern is preserved; it's just no longer the default for everything.

## Files in this bundle

```
design-modern-editorial/
├── INSTALL.md                  ← this file
├── SKILL.md                    ← rewritten, primitives-first
└── reference/
    ├── principles.md           ← NEW: invariants in prose form
    ├── tokens.css              ← unchanged (small comment update)
    ├── dashboard.html          ← unchanged
    ├── article.html            ← NEW: long-form writing
    ├── marketing.html          ← NEW: landing page
    ├── poster.html             ← NEW: A3 poster
    ├── slide.html              ← NEW: 16:9 slide
    └── email.html              ← NEW: narrow-column email
```
