# Principles — Modern Editorial

This file is the prose form of the system's invariants. Read it whenever you're applying the style to a medium that doesn't have its own worked reference (book cover, packaging, app icon, social card, etc.). It's also a useful re-grounder when an artifact starts to drift.

The system has two layers:

**Invariants** — rules that hold across every medium. If any is violated, the artifact has left the system.

**Primitives** — moves you can reach for in any medium. They may or may not all appear; the goal is the right two or three for the artifact, not all of them.

There is also a third layer of *components* (stat ledgers, catalog tables, fleuron colophons, etc.) — but those live in the worked references and only apply when the artifact's content actually maps to them. Don't impose them.

## Invariants

### Type stack

- **Fraunces** for display and italic emphasis. Always set `font-variation-settings: "opsz" 144, "SOFT" 0, "WONK" 1` on display sizes, and `"opsz" 144, "SOFT" 100, "WONK" 1` on italic display. The WONK axis is what gives Fraunces italics their characterful slant — without it the italic looks generic. SOFT keeps display sizes from going austere.
- **Geist** for body, labels, and UI sans.
- **Geist Mono** for technical chrome — timestamps, IDs, axis labels, pill badges, eyebrow text.
- Italic is reserved for `<em>`. Never default `font-style: italic` on body copy.
- Tabular figures everywhere — `font-feature-settings: "tnum"` on the body.
- Substituting any of these three faces is the fastest way to lose the aesthetic. If the rendering environment doesn't have them, document the substitution clearly (e.g. in a colophon line) — don't pretend.

### Surface

- Background is `--paper` (`#FAFAF6`) — bright but not sterile, the slightest cream hint.
- Text is `--ink` (`#14110E`) — warm near-black, never pure black.
- No paper grain, no noise overlays, no dark mode unless explicitly requested.
- White (`--paper-2`, `#FFFFFF`) is reserved for the rare case of an elevated surface; it's almost never used.

### Hairlines, not boxes

This is the structural rule that does the most work. Sections are separated by `1px` hairline borders, never by cards, panels, tinted backgrounds, or shadows.

- `--hair` (`rgba(20,17,14,0.12)`) for sub-row dividers.
- `--hair-2` (`rgba(20,17,14,0.26)`) for section dividers.
- No `box-shadow` for elevation. Elevation is a hairline above and below.
- No rounded corners greater than 2px. The exception is fully-rounded pills for stage indicators (`border-radius: 100px`).

### Color is semantic

- The five jewel-tones (`--indigo`, `--accent`, `--leaf`, `--mustard`, `--plum`) are *Linear-style* — saturated, premium, modern. They are not earth-tones.
- Each appearance must map to a real category, status, or stage in the *current artifact's* content. If you cannot articulate what a color means here, remove it.
- Maximum two saturated jewel-tones visible at once without a semantic reason for both being present.
- The role mappings shown in `tokens.css` (`indigo` = first/start, `accent` = in-progress, etc.) are *typical* mappings inherited from the dashboard. Re-bind them to your content's actual categories.
- No purple-to-blue brand gradients. Ever. This is the single biggest "AI slop" tell.

### The highlighter exception

The yellow highlighter underline behind a single italic word is the only gradient permitted in the system, because it's diegetic — it looks like a real pen stroke.

- Use it once per artifact. Not per page, not per section — per artifact.
- Always under an italic word, almost always one word, occasionally a short phrase.
- Implementation:

```css
.marked {
  background: linear-gradient(
    transparent 62%,
    var(--marker-soft) 62%,
    var(--marker-soft) 92%,
    transparent 92%
  );
  padding: 0 0.04em;
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
}
```

- The pseudo-stop positions (`62%` and `92%`) are calibrated. Don't tweak them.
- A second appearance kills the moment. If you find yourself reaching for it twice, pick the one that lands harder and remove the other.

## Primitives

These are the moves available in any medium. Pick the two or three that fit; don't try to use all six.

### Big italic Fraunces display

Used for hero headlines, large numerals, opening titles, pull-quote openers — anything 28px and up. Pair with the highlighter trick once if the headline needs an editorial moment.

### Hairline divider

The structural workhorse. Replaces every card, panel, and shadow. A horizontal hairline between sections; vertical hairlines inside ledgers and tables.

### Eyebrow row

A small editorial line above any major section: a short hairline rule, an uppercase mono label (letter-spacing ~0.18em), and an optional italic-serif aside on the right. Two lines of effort, immediate editorial register.

### Footnote-style superscript

A mono-numeric superscript in `--accent` red, attached to named entities (works, products, people, places). Ties the artifact to the literary lineage of the system. Use them as you would in a printed essay — sparingly, on names that warrant a reader's attention.

### Spot-color chip

A 9px circle in one of the five jewel-tones, set inline with a label. Use whenever items belong to a fixed category set with at most five categories.

### Italic emphasis

The mood-setter. A single italicized word in the middle of a sentence does the work that bold would do in lesser typography. Used inside `<em>` only.

## A note on layout

- Asymmetric grids feel right (1.55fr / 1fr, 1.7fr / 1fr) — symmetric ones feel corporate.
- Generous padding. Heroes at 64-88px vertical. Body padding at 32-48px horizontal on a wide surface.
- Section markers — `§ 1.0`, roman numerals (i, ii, iii) — feel academic and editorial. Use them when the artifact has formal sections; skip them otherwise.

## A note on motion

If used at all, restraint is the rule.

- One staggered fade-up cascade on page load, sections delayed in 50-60ms increments.
- Easing: `cubic-bezier(.2,.7,.2,1)`. No bounces, no overshoots.
- Chart lines draw in via `stroke-dashoffset` from path length to 0, ~2.4s, ease `cubic-bezier(0.65, 0, 0.35, 1)`, after a ~700ms settle delay.
- No micro-interactions on hover beyond color shifts.

## Self-check

If, when you're done, the artifact looks like a sub-page of the dashboard reference, you've imitated rather than translated. Strip the chrome and check whether the underlying artifact still works. The system should sit *on top* of a sound piece — not constitute it.
