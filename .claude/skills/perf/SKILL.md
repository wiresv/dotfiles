---
name: perf
description: Run a Lighthouse performance audit against the local dev server with throttled CPU/network simulation.
---

Run a production-realistic Lighthouse performance audit against the local dev server.

## Pre-flight checks (abort with explanation if any fail)

- Verify Chrome is installed: check `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` (macOS) or `which google-chrome` / `which chromium` (Linux)
- Check if the dev server is responding on port 3000:
  ```
  curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
  ```
  - If not running, start it with `bun run dev &` from the project root, wait 3 seconds, verify again
  - Note if you started the server so you can tell the user
- Verify `lighthouse` is available: `npx lighthouse --version`
  - If not available, run `bun add -d lighthouse` in the project root and retry

## Run the audit

Execute Lighthouse in headless mode:

```bash
npx lighthouse http://localhost:3000 \
  --only-categories=performance \
  --preset=desktop \
  --chrome-flags="--headless --no-sandbox" \
  --throttling-method=simulate \
  --output=json \
  --output-path=stdout \
  --quiet 2>/dev/null
```

Capture the full JSON output.

**Note:** `--preset=desktop` is used because this app targets desktop users (3-column layout). If the user asks for a mobile audit, drop `--preset=desktop` and use `--form-factor=mobile` with default Lighthouse throttling instead.

## Extract and present metrics

Parse the JSON and present a clean, aligned summary:

**Performance Score** — `categories.performance.score` × 100

**Core Web Vitals** with pass/fail:
- FCP from `audits.first-contentful-paint` — good < 1.8s, needs-improvement < 3.0s, poor ≥ 3.0s
- LCP from `audits.largest-contentful-paint` — good < 2.5s, needs-improvement < 4.0s, poor ≥ 4.0s
- CLS from `audits.cumulative-layout-shift` — good < 0.1, needs-improvement < 0.25, poor ≥ 0.25

**Other Metrics:**
- TBT from `audits.total-blocking-time` — good < 200ms, needs-improvement < 600ms, poor ≥ 600ms
- Speed Index from `audits.speed-index`
- TTI from `audits.interactive`

**Payload Breakdown** — from `audits.resource-summary.details.items`:
- List each resource type (document, stylesheet, script, image, font, other) with transfer size and request count
- Show total

Use ✅ for good, ⚠️ for needs-improvement, ❌ for poor.

## HTML report

After presenting the summary, offer to generate a full HTML report. If the user accepts:

```bash
npx lighthouse http://localhost:3000 \
  --only-categories=performance \
  --preset=desktop \
  --chrome-flags="--headless --no-sandbox" \
  --throttling-method=simulate \
  --output=html \
  --output-path=./lighthouse-report.html \
  --quiet 2>/dev/null
```

Tell the user to open `lighthouse-report.html` in their browser.

## Housekeeping

If `lighthouse-report` is not already covered by `.gitignore`, add `lighthouse-report*` to the project's `.gitignore`.
