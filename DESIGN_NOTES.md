# DESIGN_NOTES — functionalmultiplicity.com

Living reference for design + accessibility principles. Future Claude sessions read this before changing visual or content patterns.

Last updated: 2026-04-14

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
- Each page using the dictionary must include the `<div id="did-tooltip">` element + `<script src="/did-tooltip.js">`.
- **⚠️ Silent-failure gotcha:** the script bails on `if (!tip) return;` if the `<div id="did-tooltip">` is missing — meaning a page can have `did-term` wrappers AND load the script, and tooltips just never fire (no console error, no visible failure). When adding a page that uses DID terms, ALWAYS include both the script tag AND the tooltip div block. Sweep with `grep -L 'id="did-tooltip"' $(grep -l 'src="/did-tooltip\.js' *.html **/*.html)` to catch any pages that load the script without the div.
- **Cache-bust convention:** the script is cached 1yr immutable per `_headers`. To force browsers to pick up a new DICT entry, bump the `?v=N` query string on every page's script tag (`/did-tooltip.js?v=2` → `?v=3`, etc.). Site-wide find/replace via sed across all `*.html` files.

### Cache-bust applies to CSS too

Same principle applies to `/styles.css` and `/styles-additions.css` — both are `max-age=31536000, immutable` per `_headers`, so any edit needs a `?v=N` bump on every `<link href="...?v=N">` tag site-wide. Starting version: `?v=1`. Bump in lockstep across both files (or per file — either works) when styles change.

**Gotcha that bit us 2026-04-14:** I added `.ai-copy-all` to `styles-additions.css` and pushed, but didn't bump the `?v=N` query. Browsers with cached copies served the button with zero styling (user-agent default: white bg + dark text). Hard-refresh (Ctrl+Shift+R) works as a workaround for the editor; for all visitors, the cache-bust is the real fix.

### Any asset in `_headers` marked `immutable` needs the same treatment

Currently: `/fonts/*`, `/*.woff2`, `/*.svg`, `/*.png`, `/*.jpg`, `/*.ico`, `/*.js`, `/*.css`, `/pagefind/*`, `/favicon.svg`. Only `did-tooltip.js`, `styles.css`, and `styles-additions.css` currently have `?v=N` query strings. Others don't change often but will need the same treatment if they do.

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

## 8. Information Architecture (Our Story / Our Field Guide / Your Field Guide)

**Top nav** (3 items, every page): **Our Story** (`/our-story`), **Our Field Guide** (`/our-field-guide/`), **Your Field Guide** (`/your-field-guide`). The FM logo links to `/`.

**Homepage `/`** is an intro hub — single intro card with H1, tagline, plural-voice framing paragraphs (covering what FM is, why this site exists, the fusion disclosure, and a closing recommendation line that points to `/our-story`). No long-form content, no scroll transition. Awaiting further direction on what else lives here.

**`/our-story`** carries the long narrative: Functional Multiplicity approach, Characteristics-not-Symptoms, the Exocortex section, Steal from the Greats / NF HOPE album notes, and a two-path next-steps closer (Our Field Guide for case-study depth / Your Field Guide for active practice). 5K+ words.

**`/our-field-guide`** is the case-study / proof-of-concept — what Nile built using FM in his own System. Contains: Index landing (4 SVG-icon tiles), AI Instructions, Chapters (3 chapters), Dictionary & Thesaurus, Tools.

**`/your-field-guide`** is the configurable framework / generator (formerly `/handbook`). Body text rebranded from "Handbook" to "Your Field Guide" / "field guide" in visible copy. CSS class names (`.handbook-main`, `.handbook-section`, `.handbook-layout`) and HTML IDs (`id="handbook-ai"`, etc.) preserved as structural scaffolding — do NOT rename without parallel CSS file edits.

Old URLs (`/handbook`, `/AIInstructions`, `/chapters`, `/DictionaryThesaurus`, `/tools`, `/introduction`, `/atomic-lego-set`, `/multi-venn`) intentionally 404 — explicit decision to skip 301 redirects. Site was early/low-traffic enough to absorb the change.

The `Our` / `Your` pronoun pairing is pedagogical: it enacts the site's Plural-immersive convention in the navigation itself (Our Story → see what we did → Our Field Guide → see what we built → Your Field Guide → build your own).

**Active-state convention:** each page marks its own nav item with `class="nav-link nav-link--active" aria-current="page"`. The homepage `/` has NO active nav item — the FM logo is the home link, and the page itself isn't represented in the 3-item nav.

**Heading convention:** exactly one `<h1>` per page. The page's canonical title lives in the H1 — homepage = "Functional Multiplicity", /our-story = "Our Story" (accent-styled via `.our-story-title`), /our-field-guide tiles page = "Our Field Guide", /your-field-guide = "Your Field Guide", chapter pages = chapter title. Subsection titles use `<h2>` and below, never `<h1>`. Enforced by the audit script (`scripts/audit.py`).

## 9. Cache Headers — `_headers` File Pattern

**Critical gotcha:** CF Pages `_headers` rules **accumulate** when multiple paths match the same file — they do NOT override. Multiple matching rules result in multiple `Cache-Control` headers stacking in the response, and browsers consolidate using the **most restrictive** directive (smallest `max-age`, plus `must-revalidate`, etc.). This silently defeats long-cache strategies.

Rules to follow when editing `_headers`:
- **Do not use `/*` catch-all.** It will match every asset and stack with their specific rules.
- **Do not duplicate** `/styles.css` AND `/*.css`. Use only the wildcard.
- **List HTML routes explicitly** rather than relying on a catch-all to exclude assets.
- For folder-routed pages (`/our-field-guide/` serving `our-field-guide/index.html`), add explicit rules for both the URL pattern AND the underlying `index.html` file path — CF Pages applies its default `max-age=0, must-revalidate` to bare `index.html` files which will stack otherwise.

Current state (verified 2026-04-14): HTML pages = `max-age=3600, must-revalidate`; assets = `max-age=31536000, immutable`; single Cache-Control header per route (except `/our-field-guide` which has 2 identical headers — cosmetic, browser consolidates).

**Zone-level overrides:** CF zone Cache Rules in `http_request_cache_settings` ruleset can force `override_origin` mode and clamp all responses to a fixed TTL regardless of `_headers`. The `functionalmultiplicity.com` zone had two such template rules — both deleted 2026-04-14 (`72c9f10e376949278af19582e71ab658` for edge_ttl, `4149fc8bdc394fc99390d8eb1520136e` for browser_ttl). Don't recreate without intent. Browser Cache TTL zone setting is also 0 (= Respect Existing Headers).

## 10. Anchor Hover Specificity Trap

The global `a:hover` rule sets `background: var(--accent)` + `color: var(--accent-on)` — designed for inline text links that get a solid green pill on hover. Specificity `(0,1,1)`.

If you wrap a complex card / tile in `<a>` and only set a subtle background change on `:hover`, the global rule still applies `var(--accent-on)` (near-black in dark mode, white in light mode) to the anchor's text color. Any descendant text inheriting color (no explicit color set) becomes unreadable.

Defenses (use both):
- Set `color: var(--text)` on the descendant text element directly so it stops inheriting from the anchor.
- Set `color: var(--text)` on the tile's `:hover` state (specificity `(0,2,0)` beats `a:hover`'s `(0,1,1)`).

Live example: `.fg-tile-desc` and `.fg-tile:hover` in `our-field-guide/index.html`.

## 11. Long-Form Formatting Conventions (NN/g-derived)

Nielsen Norman Group research on formatting long-form content (https://www.nngroup.com/articles/formatting-long-form-content/) sets the threshold at ~1,000 words. Pages above that get formatting techniques to reduce reader fatigue and enable scanning. Full distillation lives in Anytype "Long-Form Content Formatting — NN/g" (object `bafyreig2gzxq7gsgm7fje4rwhwxguv6r46nzbwo3yktrdzznh2hbh3o7xa`) and Drive `/PARA/Resources/long_form_formatting_nng/`.

Applied to FM site (verified 2026-04-14):

- **Reading-time meta** (`<p class="page-meta">~X min read</p>`) under H1 on every long-form page. Computed at ~200 wpm, rounded. CSS `.page-meta` in `styles-additions.css` (subtle muted line, matches `.fg-tile-meta`). Pages stamped: introduction (~3 min), atomic-lego-set (~6), multi-venn (~12), dictionary-thesaurus (~5), your-field-guide (~15), ai-instructions (~24).
- **Bold-density audit:** all pages well under the 30% NN/g ceiling. Highest is ai-instructions at 4.2%. Compliant.
- **Bullet-first style** (FM Style Guide rule 4b) and informational-only imagery: already aligned.
- **AI Instructions page — separate concern:** this page is primarily consumed by AI (copy-paste or URL fetch), not read by humans top-to-bottom. NN/g conventions soften here. Specifically: a Copy All button (outlined `.ai-copy-all`) sits above section content for the copy-paste workflow; Jump-to TOC removed as it had zero value for AI readers; opening directive block simplified to two sentences (italic framing + direct "scan this entire website" instruction). Anchor IDs on each section retained for deep-linking.
- **Closed (previously pending):** Fibery #10 (TL;DR on AI Instructions) and #11 (accordions on AI Instructions) both closed — the page is for AI consumption; human-scannability formatting adds friction to the primary workflow of copy-paste-into-AI.
- **Pending (Fibery #12, due 2026-04-18):** section-end summaries on Your Field Guide + Multi-Venn (both have human readers; still valid work).

**`/our-story` is intentionally excluded from these conventions.** No reading-time, no top summary, no section-end closers. Per Nile's directive: visitors "earn" the content; the immersive narrative is the entry point and must not be pre-graded.

## 12. Homepage `/` — DID-Term Tooltip First-Appearance Anchor

Because `/` is now the cold-start landing (intro card only), it is the canonical first-appearance page for site-wide DID terms. Per the wrap density rule (Section 3, "first appearance only in chronological reader sequence"), terms wrapped on `/` should NOT be re-wrapped on subsequent pages a typical reader visits next (Our Story, Our Field Guide, etc.).

Currently wrapped on `/` (verified 2026-04-14): Functional Multiplicity, DID, OSDD, Plurality, System (`data-did="system"`), Plural (`data-did="plural"`).

Words deliberately left unwrapped on `/`: "Multiplicity" (no exact dict entry; close to "plurality" but distinct concept), "fused" / "confluence" (the closest dict entry "integration" carries a meaning FM explicitly rejects, would mislead). When/if these gain dict entries, revisit the wrap decision.

## 13. Dictionary Page Conventions (`/our-field-guide/dictionary-thesaurus`)

The page has two `<dl>` blocks: **DIDictionary** (FM-specific terms, system mechanics) and **Theysaurus** (community synonyms). Both alphabetized **A-Z by `<dt>` term, case-insensitive**.

When adding new entries:
- Insert in alphabetical position; do NOT append to the end.
- Capitalize the term in title case for `<dt>` (e.g. "Co-Hosting", "System Mechanics").
- Definition in `<dd>` ends with a period.
- Use Plural-language convention inside definitions ("Members", "Their", "You" capitalized when referring to people).

**No subtitle paragraphs above the `<dl>` block.** If a description belongs on the page, convert it to a proper `<dt>`/`<dd>` entry and place it in alphabetical order (the original "System mechanics — how plurality works from the inside" subtitle was converted to a System Mechanics entry between Stasis and System Mapping). Theysaurus retains its `<p>Synonyms and overlapping terms...</p>` subtitle for now — pending a similar conversion if/when desired.

Cross-link relationships in definitions use prose (e.g. Co-Consciousness's definition references Co-Hosting), not anchor links — keeps the dictionary scannable.

## 14. Centered-Main-Content with Sidebar Layout

Pages with a sidebar TOC (currently: `/your-field-guide`) use a 3-column CSS grid so the main content is visually centered in the viewport regardless of sidebar presence. Pattern:

```css
.handbook-layout {
  display: grid;
  grid-template-columns: 200px minmax(0, 1fr) 200px;  /* sidebar | main | mirror spacer */
  max-width: 80rem;
  margin: 0 auto;
  padding: 0 1.5rem;
  gap: 3rem;
  align-items: flex-start;
}
.handbook-main {
  max-width: 48rem;
  margin: 0 auto;  /* center within the fluid middle column */
}
```

The third column is an empty 200px spacer that mirrors the sidebar's width. Main content's `margin: 0 auto` centers it inside its fluid middle column → visually centered in the viewport.

Mobile breakpoint (≤800px): `grid-template-columns: 1fr` collapses to single-column stack. Sidebar flows above main.

**Why not flex:** flexbox pushes main content right-of-center when sidebar occupies the left flex child. Symmetric grid spacers are the simplest fix that doesn't require absolute positioning (which would break the sidebar's `position: sticky`).

**Why not just widen the container:** widening without a mirror spacer still leaves main right-of-center — widening changes the offset magnitude but not direction.

This pattern is portable to any future page with a left sidebar + centered main. If sidebar width changes, keep left and right columns symmetric.

## 15. Button Convention

Two button styles, used for distinct roles:

- **`.btn`** — solid green fill (`--accent` bg + `--accent-on` text). **Use for: primary navigation CTAs** that move visitors to another page. Live examples: "Open Our Field Guide →", "Open Your Field Guide →" on `/our-story`. The solid fill is visually distinct enough from inline `<strong>` green that they don't compete in practice (different weight, different chrome).
- **Outlined button** (transparent bg + `--accent` 1.5px border + `--accent` text, hover = 12% accent tint). **Use for: auxiliary actions** on a page that don't navigate. Live example: `.ai-copy-all` (Copy All Instructions button on `/our-field-guide/ai-instructions`).

**Decision rule (resolved 2026-04-14):** if the button's action is "go somewhere else," use `.btn` (solid). If the action is in-page (copy, toggle, trigger, reveal), use the outlined variant. Create a new CSS class per auxiliary-action context (`.ai-copy-all` for that specific button) rather than a generic shared outlined `.btn-outline` — keeps button purpose visible in the class name.

## 16. Audit Script

`scripts/audit.py` runs the structural audit used to verify the site before/after changes:

```bash
python3 scripts/audit.py          # static checks only (fast, local)
python3 scripts/audit.py --live   # + HTTP + cache-header live checks
```

Checks: internal link + anchor integrity, tooltip/DICT coverage, cache-bust consistency, stale "Handbook" naming, metadata sanity (canonical/og:url match, H1 count per page), skip-link targets.

Report-only — no changes made. Re-run after any batch of HTML/CSS/DICT edits. See also the full audit report procedure documented in the conversation log from 2026-04-14 (ClickUp doc `8cr51kc-3317` Corrections section #2).
