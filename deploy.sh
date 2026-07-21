#!/bin/bash
# deploy.sh — deploy functionalmultiplicity.com to Cloudflare Pages, purge, verify.
# Usage: bash /home/nile/functionalmultiplicity.com/deploy.sh
#
# 2026-07-16 rewrite. Two changes, both born from a real incident that day:
#
#  1. REMOVED the ClickUp live-copy backup (old steps 2, 4, 5) + html_to_md.py dep.
#     ClickUp was deprecated 2026-06-08; subscription lapses Feb 2027. The old script
#     did `exit 1` when CLICKUP_API_KEY was missing — BEFORE the deploy step — so the
#     day that key dies, this script stops deploying and reports "Could not fetch
#     CLICKUP_API_KEY" instead of "your site did not ship". The backup was redundant
#     three times over: the site is in git, and CF Pages retains every deployment.
#
#  2. ADDED purge + live verify.
#     On 2026-07-16 wrangler printed "✨ Success!" while production served the OLD
#     HTML for 25 minutes. Causes: a zone Cache Rule forces edge_ttl 3600 with
#     mode=override_origin on every GET, and Tiered Cache is ON — so a by-URL purge
#     is a no-op and only purge_everything clears it. `cf-cache-status: DYNAMIC`
#     lied throughout.
#     => A deploy that isn't visible is not a deploy. Purge, then PROVE the new
#        bytes are live before reporting success.

set -euo pipefail

SITE_URL="https://functionalmultiplicity.com"
ZONE_ID="ada98c90c426184c68082db26010a8ae"
GCP_PROJECT="popos-and-mcp"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Canary: a page whose bytes change when a deploy lands. Used to prove liveness.
CANARY_PATH="/our-story"

echo "=== FM Deploy Pipeline ==="
date '+%Y-%m-%d %H:%M:%S'
echo ""

# ── 1. Secrets (fetched inline; never echoed, never written to disk) ──────────
# CLOUDFLARE_API_KEY = scoped Pages-deploy token. wrangler v4 rejects the legacy
# Global API Key (cfk_ prefix). Expires 2026-12-31 — rotate before then.
echo "Fetching Cloudflare deploy token from GSM..."
CLOUDFLARE_API_TOKEN=$(gcloud secrets versions access latest \
  --secret=CLOUDFLARE_API_KEY --project="$GCP_PROJECT" 2>/dev/null || true)
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "ERROR: could not fetch CLOUDFLARE_API_KEY from GSM — SITE NOT DEPLOYED."
  echo "       Run: gcloud auth login"
  exit 1
fi
echo "✓ deploy token loaded"

# CLOUDFLARE_PURGE_TOKEN = least-privilege token: Cache Purge on this zone ONLY.
# Minted 2026-07-16 ("fm-cache-purge-deploy"); negative-tested — it cannot read DNS.
# The deploy token deliberately lacks Zone:Cache Purge. Do NOT widen it, and do NOT
# put CLOUDFLARE_GLOBAL_API (full-account key) in this script.
PURGE_TOKEN=$(gcloud secrets versions access latest \
  --secret=CLOUDFLARE_PURGE_TOKEN --project="$GCP_PROJECT" 2>/dev/null || true)
if [ -z "$PURGE_TOKEN" ]; then
  # Non-fatal BY DESIGN: a missing purge token must never block shipping. But loud —
  # a silent skip here means a deploy that looks live and isn't.
  echo "⚠ WARNING: CLOUDFLARE_PURGE_TOKEN missing — will deploy but CANNOT purge."
  echo "           The zone caches HTML for 1h (override_origin), so the change may"
  echo "           not be visible for up to an hour. Purge manually or wait."
else
  echo "✓ purge token loaded"
fi
echo ""

# ── 2. Deploy to Cloudflare Pages ────────────────────────────────────────────
echo "Deploying to Cloudflare Pages..."
cd "$SCRIPT_DIR"
DEPLOY_OUTPUT=$(CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
  npx wrangler pages deploy . --project-name=functionalmultiplicity --commit-dirty=true 2>&1)
echo "$DEPLOY_OUTPUT"
DEPLOY_URL=$(echo "$DEPLOY_OUTPUT" | grep -oE 'https://[a-z0-9]+\.functionalmultiplicity\.pages\.dev' | head -1 || true)
echo ""

# ── 3. Purge the edge cache ──────────────────────────────────────────────────
# purge_everything, NOT by-URL: Tiered Cache is ON, which makes a files[] purge
# unreliable across tiers (verified 2026-07-16 — the by-URL purge was a no-op).
# 16-page static site; origin refill cost is negligible.
if [ -n "$PURGE_TOKEN" ]; then
  echo "Purging Cloudflare cache (purge_everything — Tiered Cache is on)..."
  PURGE_OK=$(curl -s -m 30 -X POST \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
    -H "Authorization: Bearer $PURGE_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"purge_everything":true}' \
    | python3 -c 'import sys,json; print(json.load(sys.stdin).get("success"))' 2>/dev/null || echo "False")
  if [ "$PURGE_OK" = "True" ]; then
    echo "✓ cache purged"
  else
    echo "⚠ WARNING: purge FAILED — the site may serve stale HTML for up to 1h."
  fi
  echo ""
fi

# ── 4. VERIFY the new bytes are actually live ────────────────────────────────
# wrangler's "Success!" describes an upload, not a live site.
#
# THIRD version of this check. The first two both produced FALSE PASSES, for
# opposite reasons, and the shape of the mistake is the same each time: the
# check had no absolute reference, so it compared something to itself.
#
#   v1 (pre-2026-07-16): compared public URL vs deployment URL on a FIXED canary
#       (/our-story). When that page hadn't changed, both sides were identical
#       and it passed on a deploy that never shipped. It compared a file to itself.
#
#   v2 (2026-07-16): compared bare URL vs CACHE-BUSTED URL of a page that DID
#       change. Better -- but it tests CONSISTENCY, not FRESHNESS. On 2026-07-20
#       at 21:05 a purge had not yet propagated, so BOTH fetches returned the old
#       page, they agreed, and it printed "✓ VERIFIED" while users were on stale
#       bytes. The content only landed ~4 minutes later. Two stale fetches agreeing
#       is not evidence of anything.
#
#   v3 (this one): assert against LOCAL TRUTH. Derive from `git diff HEAD~1 HEAD`
#       two strings -- one that exists ONLY in the version just deployed, one that
#       existed ONLY in the previous version -- then require the live page to
#       CONTAIN the first and NOT CONTAIN the second. Stale bytes fail both by
#       construction: they still carry the old string and still lack the new one.
#       There is no pair of fetches that can agree its way past this.
#
#   v3.1 (2026-07-20 23:31): v3's uniqueness test was bogus, so it produced a
#       permanent FALSE FAILURE (the inverse of the earlier false passes) on any
#       revert or in-place line edit. It asked `seg not in <segments from the
#       other side>` -- Python list membership, i.e. exact element equality --
#       and it asked BEFORE truncating the string to the 120 chars actually used
#       for matching. An in-place sentence edit leaves two variants of one
#       paragraph sharing a long prefix: the two lists hold no common element,
#       so the check passed, and the 120-char prefix it then handed to grep was
#       present in BOTH versions. MUST_VANISH could never vanish, so a correct
#       deploy could never verify. v3.1 validates the exact truncated string
#       against the actual files: the deployed one and the previous one.
#
#   v3.2 (2026-07-21): the assertions were being inverted by a SHELL bug, not by
#       the edge. `set -euo pipefail` (line 22) combined with
#       `printf '%s' "$PAGE" | grep -q ...` is unsound: grep -q exits the instant
#       it matches, which SIGPIPEs the still-writing printf, and pipefail then
#       reports the whole PIPELINE as failed. So a successful MATCH returned
#       non-zero -- `|| A_OK=0` fired on success, and `&& V_OK=0` never fired
#       even when the old text WAS still on the page. That is where the
#       impossible pair `new-text-present=0 old-text-gone=1` came from: a page
#       that is apparently neither version. The vanish half failed in the
#       DANGEROUS direction -- genuinely stale bytes would report "old text
#       gone" and pass that check.
#       Proven against the live page 2026-07-21: needle present (grep -c = 1),
#       yet A_OK=0 on 5/5 runs under pipefail and A_OK=1 on 3/3 without it.
#       Fix: no pipeline at all. The body is written to a file and grepped
#       directly, which also leaves the artifact on disk to diagnose from.
#       Diagnosis cost three wrong root-cause theories first (bot-blocking,
#       apostrophe encoding, entity decoding) because a failure printed only
#       THAT it failed. Hence the instrumentation below.
#
# Design rule for anyone editing this again: a verification step must be able to
# FAIL for the reason it exists, and must be able to PASS when the deploy is
# good. If you cannot state the input for each, it is decoration. (All three
# prior versions passed their own author's eyeball test.)
# Corollary added 2026-07-21: it must also distinguish "I could not look" from
# "I looked and found nothing", and when it fails it must print enough to say
# WHY -- a bare verdict sends the next reader down invented explanations.
#   fails when: the edge still serves the old page -> MUST_APPEAR is missing.
#   passes when: the edge serves the bytes just uploaded.
#   asserts nothing (loudly) when: no string can be shown unique to one version.

echo "Verifying deploy is LIVE (not just uploaded)..."
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

# Which HTML page changed in this commit? That page is the canary.
CANARY_FILE=$(git -C "$SCRIPT_DIR" diff --name-only HEAD~1 HEAD 2>/dev/null | grep '\.html$' | head -1 || true)

ASSERT_DIR=$(mktemp -d)
trap 'rm -rf "$ASSERT_DIR"' EXIT

if [ -n "$CANARY_FILE" ]; then
  CANARY_PATH="/${CANARY_FILE%.html}"
  CANARY_PATH="${CANARY_PATH%/index}"
  # Extract the assertions. Text runs only -- never markup, never attributes,
  # never anything containing an @ or mailto (Cloudflare rewrites those at the
  # edge, which would make a correct deploy look broken).
  git -C "$SCRIPT_DIR" diff HEAD~1 HEAD -- "$CANARY_FILE" > "$ASSERT_DIR/d.diff" 2>/dev/null || true
  # The two absolute references every candidate is validated against.
  #   new.html = the bytes we just uploaded. Deliberately the WORKING TREE, not
  #     HEAD, because the tree is what shipped. So the assertion is always about
  #     what was actually uploaded, never about what HEAD claims. If the tree is
  #     dirty, candidates the uploaded bytes don't satisfy are simply rejected;
  #     any that survive are still true of the deployed file. (Do not upgrade
  #     that to "a dirty tree cannot verify" -- tested 2026-07-20, it can, and
  #     correctly so. This check proves liveness, not tree/HEAD agreement.)
  #   old.html = the version the edge may still be serving. Absent (new page,
  #     or first commit) is fine: it just means nothing old can contain our text.
  cp "$SCRIPT_DIR/$CANARY_FILE" "$ASSERT_DIR/new.html" 2>/dev/null || true
  git -C "$SCRIPT_DIR" show "HEAD~1:$CANARY_FILE" > "$ASSERT_DIR/old.html" 2>/dev/null || true
  python3 - "$ASSERT_DIR" <<'PY'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
diff = (d / "d.diff").read_text(encoding="utf-8", errors="replace")
MAXLEN = 120                              # the length grep actually matches on

def read(name):
    p = d / name
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

new_text, old_text = read("new.html"), read("old.html")

def runs(prefix):
    """Longest contiguous TEXT run (no tags) from lines added/removed by the diff."""
    out = []
    for ln in diff.split("\n"):
        if not ln.startswith(prefix) or ln.startswith(prefix * 3):
            continue
        body = ln[1:]
        for seg in re.split(r"<[^>]*>", body):
            seg = seg.strip()
            if len(seg) < 20:            # too short to be distinctive
                continue
            if "@" in seg or "mailto" in seg:   # CF rewrites these at the edge
                continue
            out.append(seg)
    out.sort(key=len, reverse=True)
    return out

def pick(cands, must_contain, must_not_contain):
    """First candidate that is REALLY unique to one version, tested as the exact
    string grep will use. Truncate FIRST, then validate -- v3 validated the full
    run and then handed grep a shortened prefix that was common to both versions,
    which is how a correct deploy came to fail forever."""
    for seg in cands:
        s = seg[:MAXLEN]
        if s in must_contain and s not in must_not_contain:
            return s
    return ""

# If we cannot read what we deployed there is no absolute reference left, so
# assert nothing rather than assert something unfounded.
if new_text.strip():
    appear = pick(runs("+"), new_text, old_text)
    vanish = pick(runs("-"), old_text, new_text)
else:
    appear = vanish = ""
(d / "must_appear.txt").write_text(appear, encoding="utf-8")
(d / "must_vanish.txt").write_text(vanish, encoding="utf-8")
PY
  MUST_APPEAR=$(cat "$ASSERT_DIR/must_appear.txt" 2>/dev/null || true)
  MUST_VANISH=$(cat "$ASSERT_DIR/must_vanish.txt" 2>/dev/null || true)
  echo "  canary  : $CANARY_PATH"
  [ -n "$MUST_APPEAR" ] && echo "  expect PRESENT : ${MUST_APPEAR:0:70}"
  [ -n "$MUST_VANISH" ] && echo "  expect ABSENT  : ${MUST_VANISH:0:70}"
else
  CANARY_PATH="/our-story"
  MUST_APPEAR=""; MUST_VANISH=""
  echo "  canary  : $CANARY_PATH (no HTML changed in HEAD)"
fi

if [ -z "$MUST_APPEAR" ] && [ -z "$MUST_VANISH" ]; then
  # Be loud. A deploy we cannot verify must not print a success line that looks
  # like one -- that is how the previous two versions did their damage.
  echo "⚠ CANNOT VERIFY: no distinctive text change found in HEAD to assert on."
  echo "  The upload succeeded. Whether users see it is UNPROVEN by this script."
  echo "  Check by hand:  curl -A '<browser UA>' $SITE_URL$CANARY_PATH"
  echo ""
  echo "=== Done (deploy uploaded, liveness UNVERIFIED) ==="
  echo "Deployment : ${DEPLOY_URL:-unknown}"
  echo "Live       : $SITE_URL"
  echo "Timestamp  : $(date '+%Y-%m-%d %H:%M:%S')"
  exit 0
fi

# A control fetch of / guards the whole probe: this zone bot-blocks plain curl,
# and a 403 block page has no content to match, which reads identically to
# "the page is wrong". Absence of evidence is not evidence of absence.
OK=0
for attempt in 1 2 3 4 5 6; do
  CONTROL=$(curl -s -o /dev/null -w '%{http_code}' -m 25 -A "$UA" "$SITE_URL/" || echo 000)
  if [ "$CONTROL" != "200" ]; then
    echo "  attempt $attempt: control fetch of / returned $CONTROL — probe is VOID, retrying"
    sleep 10; continue
  fi

  # Body and status together. `curl -f` used to swallow an HTTP error into an
  # empty string, which made "the edge refused us" read identically to "the page
  # is wrong" -- the same absence-as-answer trap the control fetch guards.
  HTTP=$(curl -s -m 25 -A "$UA" -o "$ASSERT_DIR/page.html" \
           -w '%{http_code}' "$SITE_URL$CANARY_PATH" || echo 000)
  BYTES=$(wc -c < "$ASSERT_DIR/page.html" 2>/dev/null || echo 0)
  if [ "$HTTP" != "200" ] || [ "$BYTES" -lt 500 ]; then
    # NOT a staleness result. Say so in different words so it can never be
    # mistaken for one.
    echo "  attempt $attempt: COULD NOT READ page (HTTP $HTTP, ${BYTES}B) — inconclusive, not stale"
    sleep 10; continue
  fi

  # NO PIPELINE -- see v3.2. grep the file directly, and use explicit if-blocks
  # rather than && / || chains so neither pipefail nor set -e can invert or
  # short-circuit the result of a successful match.
  A_OK=1; V_OK=1
  if [ -n "$MUST_APPEAR" ]; then
    if ! grep -qF -- "$MUST_APPEAR" "$ASSERT_DIR/page.html"; then A_OK=0; fi
  fi
  if [ -n "$MUST_VANISH" ]; then
    if grep -qF -- "$MUST_VANISH" "$ASSERT_DIR/page.html"; then V_OK=0; fi
  fi

  if [ "$A_OK" = "1" ] && [ "$V_OK" = "1" ]; then
    OK=1; echo "  attempt $attempt: new text present, old text gone  ✓"; break
  fi
  echo "  attempt $attempt: STALE — new-text-present=$A_OK old-text-gone=$V_OK (HTTP $HTTP, ${BYTES}B)"
  # A_OK=0 with V_OK=1 means the page is apparently NEITHER version, which is
  # not a state a stale edge can produce. That combination indicates a broken
  # check, not a broken deploy -- it is exactly what the v3.2 pipefail bug did.
  if [ "$A_OK" = "0" ] && [ "$V_OK" = "1" ]; then
    echo "  ⚠ impossible pair: page matches neither version — SUSPECT THE CHECK, not the deploy"
  fi
  if [ "$attempt" = "2" ] && [ -n "$PURGE_TOKEN" ]; then
    echo "  -> re-purging (purge is eventually consistent; the first can silently no-op)"
    curl -s -m 30 -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
      -H "Authorization: Bearer $PURGE_TOKEN" -H "Content-Type: application/json" \
      --data '{"purge_everything":true}' > /dev/null || true
  fi
  sleep 15
done

if [ "$OK" = "1" ]; then
  echo "✓ VERIFIED: the live page carries the text from this deploy and not the previous one."
else
  echo "❌ NOT LIVE: $SITE_URL$CANARY_PATH is still serving the previous version."
  echo "   The upload succeeded but users are on old content."
  echo "   Purge manually, or wait out the edge TTL, then re-check."
  echo ""
  # ── Diagnostics ────────────────────────────────────────────────────────────
  # Preserve the evidence. ASSERT_DIR is mktemp'd and destroyed by the EXIT trap,
  # so without this copy every failure is unreproducible by the time anyone
  # reads it -- which is how one bad verdict cost three wrong root-cause
  # theories on 2026-07-21.
  DIAG="$HOME/logs/fm-deploy-fail-$(date '+%Y%m%d-%H%M%S')"
  mkdir -p "$DIAG"
  cp "$ASSERT_DIR/page.html"       "$DIAG/live-page.html"       2>/dev/null || true
  cp "$ASSERT_DIR/new.html"        "$DIAG/local-deployed.html"  2>/dev/null || true
  cp "$ASSERT_DIR/old.html"        "$DIAG/local-previous.html"  2>/dev/null || true
  printf '%s' "$MUST_APPEAR" > "$DIAG/must_appear.txt"
  printf '%s' "$MUST_VANISH" > "$DIAG/must_vanish.txt"
  {
    echo "canary        : $CANARY_PATH"
    echo "canary file   : ${CANARY_FILE:-none}"
    echo "http / bytes  : ${HTTP:-?} / ${BYTES:-?}"
    echo "A_OK (appear) : ${A_OK:-?}   V_OK (vanish) : ${V_OK:-?}"
    echo "MUST_APPEAR   : ${#MUST_APPEAR} chars"
    echo "MUST_VANISH   : ${#MUST_VANISH} chars"
    echo "deployment    : ${DEPLOY_URL:-unknown}"
  } | tee "$DIAG/summary.txt"
  echo ""
  echo "   Full assertion strings (what grep actually looked for):"
  echo "     APPEAR |$MUST_APPEAR|"
  echo "     VANISH |$MUST_VANISH|"
  echo ""
  echo "   Diagnostics saved: $DIAG"
  echo "   Reproduce:  grep -cF -f $DIAG/must_appear.txt $DIAG/live-page.html"
  exit 1   # a deploy that isn't visible is not a success
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "=== Done ==="
echo "Deployment : ${DEPLOY_URL:-unknown}"
echo "Live       : $SITE_URL"
echo "Timestamp  : $(date '+%Y-%m-%d %H:%M:%S')"
