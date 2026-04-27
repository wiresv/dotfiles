---
name: design-modern-editorial
description: Apply the Modern Editorial design system — literary-press typographic restraint (Fraunces variable-serif headlines, hairline-only dividers, italic-as-emphasis) crossed with Linear-style modern UI (off-white surfaces, jewel-tone spot colors, highlighter-yellow flourishes). Use whenever the user invokes /design-modern-editorial, asks for "modern editorial" styling, or asks to build any artifact (page, dashboard, site, app, article, slide, poster, email, report) in this aesthetic. Also trigger when the user describes wanting Fraunces serif display, hairline borders, bright off-white surfaces, semantic jewel-tone spot colors, highlighter-yellow flourishes, footnote-style markers, or a design combining "literary press"/"editorial" feel with modern Linear sensibilities. The skill carries worked examples across mediums (dashboard, article, marketing, poster, slide, email), invariants in prose, and rules for translating the style across artifacts.
---

# Modern Editorial Design System

A literary-press-meets-Linear aesthetic for any visual artifact — web pages, dashboards, articles, slides, posters, emails, PDFs, app UI. Editorial restraint (chunky variable-serif headlines, hairline rules, generous negative space, italic emphasis used sparingly) crossed with modern UI sensibilities (bright off-white surfaces, vivid Linear-style jewel-tone spot colors, contemporary type stacks). Serious and refined, but with a few earned moments of allure — a highlighter-yellow mark behind a key word, a small printer's fleuron in the colophon, color-coded legends.

## What this skill is — and isn't

**This is a *style* skill, not a *template* skill.** Its purpose is to make many different artifacts feel like they belong to one body of work. It is not a way to make every artifact look like a dashboard.

The single most important behavior: **translate the system to the medium, don't transplant components from one medium into another.** A dashboard's stat ledger, catalog table, and editorial log are *example uses* of the system — not requirements. A slide doesn't need a colophon. A poster doesn't need a stat ledger. An email doesn't need a chart. Reach for components only when the artifact's own content actually maps to them.

## Workflow — apply this skill in this order

1. **Identify the medium.** Dashboard? Article? Marketing page? Poster? Slide? Email? PDF report? App UI? Something else?
2. **Read the closest reference first.** The `reference/` directory holds worked examples across mediums (see "Reference library" below). Open the one that matches your target — that's how the system looks when adapted to that medium. If nothing matches, read `reference/principles.md`.
3. **Always read `reference/tokens.css` and `reference/principles.md`** before writing any code, regardless of medium. These define what's invariant.
4. **Compose from primitives, not components.** The "Primitives" section below is a small set of moves that travel across all mediums. The "Components" section is a longer list of *example* applications — each is appropriate only when the content fits.
5. **Restraint over inclusion.** One or two earned moments of system signature is plenty. The default is quiet typography on hairline-divided off-white paper — the spot colors and highlighter trick are accents, not the substance.
6. **Self-check before shipping** (see the section near the end). If the artifact reads like "a page from the dashboard reference," start over.

## The aesthetic in one paragraph

Bright but-not-sterile off-white paper (`#FAFAF6`) under warm near-black ink (`#14110E`). Fraunces variable serif does the heavy display work — its WONK axis gives italic letterforms their characterful slant, and the SOFT axis keeps display sizes from looking austere. Geist sans handles utilitarian labels and body. Geist Mono handles technical chrome (timestamps, IDs, axis labels). Up to one highlighter-yellow gesture per artifact. A 5-color jewel-tone palette mapped to semantic categories. Hairline 1px dividers replace cards. No shadows. No gradients except the highlighter trick. Color is rare and meaningful when it appears.

## Aesthetic invariants — must always be true

These hold across every medium. If any of them is violated, the artifact is no longer in this system.

- **Type stack:** Fraunces (display + italic emphasis), Geist (body + labels), Geist Mono (technical chrome). No Inter, Roboto, Arial, or system-ui as primary type — substituting any of these is the fastest way to lose the aesthetic.
- **Surface:** `--paper` (`#FAFAF6`) under `--ink` (`#14110E`). No noise overlays, no paper grain, no dark mode unless explicitly requested.
- **Hairlines, not boxes.** Sections separate via `border-bottom: 1px solid var(--hair-2)` (major) or `var(--hair)` (sub). No card backgrounds. No drop shadows. No rounded corners > 2px (pills excepted).
- **Italic is for `<em>` only.** Never set `font-style: italic` as the default on body copy. Italic must be earned.
- **Tabular figures** on the body (`font-feature-settings: "tnum"`).
- **Color is semantic.** Every spot-color appearance must map to a real category, status, or stage in the *current artifact's* content. If you can't articulate why a color is there, remove it.
- **No gradients except the highlighter underline.** No background gradients, no text gradients. The highlighter is a diegetic exception — it looks like a real pen.
- **No purple-to-blue brand gradients ever.** The single biggest "AI slop" tell.

## Type stack (load via Google Fonts)

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght,SOFT,WONK@0,9..144,300..700,0..100,0..1;1,9..144,300..700,0..100,0..1&family=Geist:wght@300;400;500;600&family=Geist+Mono:wght@400;500&display=swap" rel="stylesheet">
```

Roles:
- **Fraunces** (variable; axes: `opsz` 9-144, `SOFT` 0-100, `WONK` 0-1) — display headlines, editorial italic emphasis, big numerals, panel titles.
- **Geist** (300-600) — labels, body in dashboards/UI, captions, button text.
- **Geist Mono** (400-500) — timestamps, IDs, axis labels, pill badges, technical metadata.

## Color tokens

Already defined in `reference/tokens.css`. Semantic roles (use as guidance, not as fixed mappings — re-bind to your content's actual categories):

| Token | Hex | Typical role |
|---|---|---|
| `--paper` | `#FAFAF6` | Page background — the canvas |
| `--ink` | `#14110E` | Headlines, primary text, hairline-strong rules |
| `--ink-soft` | `#2A2520` | Body copy |
| `--mute` | `#54504A` | Small caps labels, technical chrome |
| `--mute-2` | `#968F86` | Decorative only — roman numerals |
| `--hair` | `rgba(20,17,14,0.12)` | Sub-row dividers |
| `--hair-2` | `rgba(20,17,14,0.26)` | Section dividers |
| `--accent` | `#E5484D` | Editor's red — footnote markers, headline period, alert states |
| `--indigo` | `#5B6CFF` | First/start states, pressmark |
| `--leaf` | `#10B597` | Refined/done states, calm-positive |
| `--mustard` | `#F58A1F` | Production/warm states, peak annotations |
| `--plum` | `#9D5BFF` | Final/final-final, "today" annotations |
| `--marker-soft` | `rgba(255,217,61,0.55)` | Highlighter underline behind italic emphasis |

These are jewel-tones, not earth-tones. Always semantic. Maximum two saturated jewel-tones visible per viewport without semantic reason.

## Primitives — always available

These six moves travel across every medium. Reach for them whenever they fit; they're how the style shows through, even on artifacts that share no structure with the dashboard.

### 1. Big italic Fraunces display

Any hero number, headline, opening title, or pull-quote larger than ~28px.

```css
.display {
  font-family: "Fraunces", serif;
  font-weight: 400;
  letter-spacing: -0.025em;
  font-variation-settings: "opsz" 144, "SOFT" 0, "WONK" 1;
}
.display i {
  font-style: italic;
  font-variation-settings: "opsz" 144, "SOFT" 100, "WONK" 1;
}
```

The `WONK` axis is what makes Fraunces italics characterful. Without `"WONK" 1` they look generic.

### 2. Highlighter-yellow underline (signature gesture)

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

```html
<i><span class="marked">seven</span></i>
```

**Use it once per artifact.** A second appearance kills the moment. This is the only gradient allowed in the system.

### 3. Hairline as the only divider

Replaces cards, boxes, and shadows everywhere. `border-bottom: 1px solid var(--hair-2)` for major divisions, `var(--hair)` for sub-rows. Never wrap a section in a colored panel.

### 4. Footnote-style superscript

```css
sup.fn {
  font-family: "Geist Mono", monospace;
  font-style: normal;
  font-size: 11px;
  font-weight: 500;
  color: var(--accent);
  vertical-align: super;
  margin-left: 2px;
}
```

Use on named entities (works, people, titles, products) in editorial copy. Ties the artifact to a literary lineage.

### 5. Eyebrow row

A small line above any major section: a hairline rule, an uppercase mono label, then an italic-serif aside on the right. Sets the editorial tone in two lines.

```css
.eyebrow {
  display: flex; align-items: center; gap: 14px;
  font-family: "Geist Mono", monospace;
  font-size: 11px;
  letter-spacing: 0.18em;
  color: var(--ink-soft);
  text-transform: uppercase;
}
.eyebrow .rule { width: 32px; height: 1px; background: var(--ink); }
.eyebrow .num {
  font-family: "Fraunces", serif;
  font-style: italic;
  color: var(--ink);
  font-size: 14px;
  letter-spacing: 0.01em;
  text-transform: none;
}
```

### 6. Spot-color chips bound to categories

```css
.chip {
  width: 9px; height: 9px;
  border-radius: 50%;
  display: inline-block;
}
.chip.indigo  { background: var(--indigo); }
.chip.accent  { background: var(--accent); }
.chip.leaf    { background: var(--leaf); }
.chip.mustard { background: var(--mustard); }
.chip.plum    { background: var(--plum); }
```

Use whenever items belong to a fixed category set with ≤5 categories. Five is the limit because it's the size of the spot palette.

## Components — example applications, content-permitting

These are larger compositions that *use* the primitives. **Each is appropriate only when the content actually fits its shape.** Do not reach for these because the dashboard reference uses them — reach for them when your artifact has the data they're built for.

| Component | Use when… | Don't use when… |
|---|---|---|
| **Stat ledger** (4-cell hairline-divided KPI strip) | The artifact reports 3-5 quantitative metrics worth pulling out of body copy. | The piece is qualitative, narrative, or single-figure. |
| **Catalog table** (Fraunces titles, mono ISBNs, stage pills) | The artifact lists ≥4 items that share a structured schema (title, status, date, ID). | A list of 2-3 items, or items without consistent metadata. |
| **Editorial log / activity feed** (timestamp + serif entry + small-caps attribution) | The artifact shows time-ordered events, notes, or updates. | A static page, marketing copy, or narrative article. |
| **Chart with hairline ink stroke + yellow wash** | The artifact has a real time series or quantity-over-axis story. | Decoration. Never include a chart for visual texture alone. |
| **Fleuron colophon** (centered all-spot-color ornament + italic-serif aside + mono right-text) | The artifact is a periodical, document, or page with a clear "end" — newsletter, report, almanac, magazine. | A slide, an email, an app screen, a landing page hero. |
| **Big italic display headline with marked word** | The artifact has one defining headline and benefits from an editorial moment. | Any place where attention should go to the body, not the title. |
| **Three-column masthead** (brand · section · meta) | The artifact is a periodical with all three of brand, section/issue, and a meta line. | A page that doesn't actually have those three things — don't pad. |

If your artifact only uses primitives and zero components, that is often the right answer.

## Reference library

Worked examples — read the one closest to your target medium first.

| File | Use as reference for | Key shapes it shows |
|---|---|---|
| `reference/dashboard.html` | Dashboards, admin UIs, internal tools, app screens with structured data. | Masthead, stat ledger, chart panel, stages rail, catalog table, editorial log, fleuron colophon. |
| `reference/article.html` | Long-form writing — essays, research notes, editorial pieces. | Article title, drop cap, prose hierarchy, pull-quote, inline footnotes, hairline section breaks. |
| `reference/marketing.html` | Landing pages, marketing one-pagers, product hero sections. | Eyebrow, big hero with marker, italic-serif lede, three-feature hairline strip, CTA, footnote-style legal. |
| `reference/poster.html` | Posters, event cards, large-format announcements. | Pure typography hero, single image area, eyebrow + meta strip, fleuron anchor. |
| `reference/slide.html` | Single deck slides, 16:9 presentation surfaces. | One big idea per slide, hairline frame, italic-serif aside, no chrome overload. |
| `reference/email.html` | Plain-style HTML emails, newsletter sections, transactional notifications. | Constrained width (~600px), no cards, hairline rules, footnote markers, simple signoff. |
| `reference/principles.md` | Anything not covered above. | Aesthetic invariants in prose form. |
| `reference/tokens.css` | Always. | CSS custom properties + base reset. |

For new mediums (T-shirt, app icon, book cover, packaging, etc.), read `principles.md` and the closest reference, then compose from primitives.

## Translate, don't transplant

Explicit do/don't pairs to short-circuit the most common mistake — copying dashboard chrome into artifacts that don't need it.

| Do | Don't |
|---|---|
| Use Fraunces for the hero headline of *anything*. | Import the dashboard's three-column masthead unless your artifact actually has brand · section · meta. |
| Use the highlighter on a single italic word, anywhere — once. | Use the highlighter twice, or on a non-italic word. |
| Use jewel-tone chips alongside category labels (≤5 cats). | Use chips as decoration, or with more than 5 categories. |
| Use hairline rules between sections. | Wrap sections in cards, boxes, or tinted panels. |
| Use footnote markers on named entities. | Use footnote markers as bullet points or list numerals. |
| Use a fleuron colophon when the artifact has a clear "end" (a periodical, a printed report). | Add a fleuron colophon to a slide, an email, an app screen, or a landing page. |
| Use a stat ledger when you actually have 3-5 KPIs. | Add a stat ledger because the dashboard has one. |
| Use the chart pattern when you have a real time series. | Add a decorative chart for visual rhythm. |
| Adopt the eyebrow pattern (rule + mono label + italic-serif aside) above any section. | Drop the dashboard's literal section labels (`§ 1.0`, `Editor's Daybook`) into unrelated artifacts. |
| Use roman numerals (i, ii, iii) for editorial section markers when the artifact has formal sections. | Sprinkle roman numerals on items that have nothing to do with sequencing. |

## Hard rules

These are non-negotiable. Skipping any of them dissolves the aesthetic.

- **No gradients except the highlighter underline.** No background gradients, no text gradients, no card gradients.
- **No drop shadows.** Hairlines do all elevation work.
- **No rounded corners > 2px.** Pills can be fully rounded for stage indicators (`border-radius: 100px`); otherwise 0-2px.
- **No Inter, Roboto, Arial, or system-ui as primary type.**
- **No purple-to-blue brand gradients.**
- **Italic on `<em>` only.** Never set `font-style: italic` as a default on body classes.
- **Tabular figures.** `font-feature-settings: "tnum"` on the body. Mandatory for any UI with numbers.
- **Maximum two saturated jewel-tone colors per viewport without semantic reason.**
- **One highlighter mark per artifact.** Not per section, not per page — per *artifact*.

## Self-check before shipping

Run these four questions before declaring done. If any answer is "no" or "I imitated rather than translated," start over.

1. **If I stripped the surface chrome — eyebrows, ledgers, fleurons, mastheads — would the artifact still serve its purpose?** If no, the system was over-applied. The chrome should sit *on top* of a working artifact, not constitute it.
2. **Could a reader who's never seen the dashboard reference understand what this artifact is for?** If they'd guess "a page of the dashboard," I imitated rather than translated. The artifact should look like its own thing, *styled* in this system.
3. **Does each spot-color appearance map to a real semantic category in *this artifact's* content?** Or is the color decorative? If decorative, remove it.
4. **Is the highlighter trick used at most once?** Is italic used only inside `<em>`? Are all dividers hairlines, never boxes?

## Adapting to mediums not yet covered

If your target isn't in the reference library, the procedure is:

1. Read `reference/principles.md` and `reference/tokens.css`.
2. Skim the two references closest in *intent* — e.g. for a book cover, read `poster.html` (hero typography) and `article.html` (long-form sensibility).
3. List the primitives you'll use and the reasons. Aim for 2-3 primitives, not 6.
4. Write the artifact. Run the self-check. Cut anything that's there for decoration.

## Common mistakes

- **Earth-tones instead of jewel-tones.** An earlier iteration of this system used sienna/forest/ochre/plum. It looked dated. The Linear-style jewel-tones (`#5B6CFF`, `#E5484D`, `#10B597`, `#F58A1F`, `#9D5BFF`) are now the system. Don't substitute.
- **Paper grain or noise overlays.** The background must be clean and modern.
- **Forgetting `"WONK" 1` on Fraunces italics.** Without it, the italic loses its characterful slant.
- **Putting a card around a chart, table, or panel.** The hairlines define the panel.
- **More than one highlighter mark.** Use it exactly once.
- **Bouncy easing.** Use `cubic-bezier(.2,.7,.2,1)` for any motion. No bounces, no overshoots.
- **Color as decoration.** Every spot-color appearance must map to a real category.
- **Dashboard transplant.** The single most common failure: copying the dashboard's section ordering (masthead → hero → ledger → chart → catalog → log → colophon) onto an artifact that doesn't need any of it. The dashboard reference is *one* worked example. Treat it as such.

## Animations (if used at all)

Restraint is the rule. One staggered fade-up cascade on page load, with each section slightly delayed. No micro-interactions on hover beyond color shifts. No bouncy easing.

```css
@keyframes fade {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}
.element { animation: fade 800ms cubic-bezier(.2,.7,.2,1) 220ms both; }
```

For chart lines, animate `stroke-dashoffset` from the path length to 0 to draw the line in. Duration ~2.4s, ease `cubic-bezier(0.65, 0, 0.35, 1)`, with a delay of ~700ms after the rest of the page settles.

## Final note

The system has been iterated through many design rounds — every value in the references is calibrated. **Treat the references as worked examples of one style across mediums, not as templates to be reproduced.** The goal is consistency across artifacts so they read as a coherent body of work — not one-off variations of the dashboard.
