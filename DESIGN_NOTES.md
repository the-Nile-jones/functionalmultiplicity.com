# DESIGN_NOTES — functionalmultiplicity.com

Living reference for design + accessibility principles. Future Claude sessions read this before changing visual or content patterns.

Last updated: 2026-04-13

---

## 1. Color & Emphasis

- **Green is the only emphasis color.** `<strong>` is auto-styled to `var(--accent)` (#50C878 dark / #1E8C4A light). Use it for skim-anchors: concept names on first mention, punchline statements, pull-out clauses.
- **`<em>` is italic only — no color.** Per-page CSS overrides any inherited color. Italic provides semantic emphasis; color is reserved for `<strong>`.
- **`--text-muted`** in dark mode = `#C8C8C8` (brightened from the original `#A0A0A0` for legibility on `#1C1C1C` bg). Used only for legitimate secondary text: subtitles, captions, footer accessibility prose, search-UI chrome. Never for emphasis.
- Avoid hardcoded greys — always go through `--text-muted`.

## 2. SVG Diagrams — Accessibility

- **Font-size floor:** body text 16px, secondary 14px, diagram annotations 12px **absolute minimum** when rendered at 768px container width. Anything smaller fails on phone (~0.4× scale).
- For dense diagrams: pull text-heavy content (lists, keys, side panels) **out of the SVG into responsive HTML below**. SVG keeps the visual structure; HTML carries the readable detail.
- Bump remaining SVG `font-size` to: title 24–26, primary labels 18–22, secondary 14–16. Crop viewBox to remove empty space after side-panels removed.
- **Click-to-enlarge pattern (mobile escape hatch):**
  - Wrap SVG in `<button class="*-zoom-trigger" aria-label="...">`
  - Add `<dialog class="*-modal">` with cloned-SVG content area
  - JS clones the source SVG into the modal on click; ESC + backdrop-click + close button all dismiss
  - CSS: `cursor: zoom-in`, accent focus ring, modal at 96vw × 92vh
  - Existing implementations: `.venn-zoom-trigger` (multi-venn.html), `.dctrl-zoom-trigger` (atomic-lego-set.html). Use a unique prefix per page if multiple diagrams.

## 3. DID Term Tooltip System (`did-tooltip.js`)

- Dictionary lives in `did-tooltip.js` (`DICT` object). Add new terms there.
- Term wrapping: `<span class="did-term" data-did="DICT_KEY">visible text</span>`
- Visible text can differ from `data-did` (case, plural, etc.); tooltip looks up by `data-did`.
- **Wrap density rule (chronological reader assumed):** wrap a term on its **first appearance only** in the chapter sequence. Don't re-wrap terms already introduced in earlier chapters.
- **Pause-test:** wrap clinical / community jargon a reader might pause on. Skip terms that are the page's central concept and explained inline.
- Each page using the dictionary must include the `<div id="did-tooltip">` element + `<script src="/did-tooltip.js">`. The script no-ops gracefully if the tooltip element is missing.

## 4. Member Relationships (multi-venn — System-specific)

Documented as canonical for the personal Multi-Venn:

- **Evee** — Architect / Anchor (center). Twin with Marc; strong working pair with Harry.
- **Marc** — Twin with Evee. Works fluidly with any Member in any capacity.
- **Harry** — Strong working pair with Evee.
- **Roe** — Navigation. Matches the right Member combination to each task.

In the Multi-Venn SVG: dashed line (3,3) = Twin Bridge (Evee↔Marc); dotted line (1,3) = Strong Pair (Evee↔Harry).

## 5. Disclosure Blockquote Convention

Every chapter ends with a Disclosure blockquote. `Claude` links to https://claude.ai/, `Anthropic` links to https://www.anthropic.com/. Both `target="_blank"` + `rel="noopener noreferrer"`.

## 6. Deploy

- Cloudflare Pages auto-deploys on `git push origin main` (~60s propagation). No `wrangler` invocation needed for routine pushes.
- `deploy.sh` runs the full pipeline (wrangler push + ClickUp live-copy backup) when you need ClickUp sync. It fetches `CLOUDFLARE_GLOBAL_API` from GSM (`gcloud secrets versions access latest --secret=CLOUDFLARE_GLOBAL_API --project=popos-and-mcp`).

## 7. CSS Caveats

- Page-specific styles inside `<head><style>` blocks are isolated to that page. When you remove a feature from one page, audit any `min-width`, `max-width`, or specificity-fragile rules left behind — they can attack later additions on the same page (e.g. an orphaned `min-width: 600px` on `.diagram-container svg` once forced a 480px wrapper to overflow).
- Global `box-sizing: border-box` is set in `styles.css`. Padding does not add to width.
