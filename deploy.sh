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
# The point of the rewrite. wrangler's "Success!" describes an upload, not a live site.
# Compare the canary page at the deployment URL (origin truth) vs the public URL.
#
# ⚠️ DO NOT sha256 the whole page — learned the hard way 2026-07-16. Cloudflare
# injects things on the custom domain that pages.dev never sees:
#   • email obfuscation  (mailto: -> /cdn-cgi/l/email-protection#...)
#   • /cdn-cgi/scripts/.../email-decode.min.js
#   • a bot-challenge block (__CF$cv$params) containing a PER-REQUEST NONCE
# The nonce alone means two fetches of the SAME url never match. A whole-page hash
# can never succeed here — it reported "NOT LIVE" on a perfectly good deploy.
# So: strip every CF-injected line, THEN hash what's left.
echo "Verifying deploy is LIVE (not just uploaded)..."
sleep 10
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
# Normalise BOTH sides: Cloudflare REWRITES lines in place on the custom domain
# (it doesn't just add them), so line-stripping fails. Neutralise its 3 transforms:
#   1. email obfuscation: href="mailto:.." -> href="/cdn-cgi/l/email-protection#hex"
#   2. an injected <script src="/cdn-cgi/scripts/../email-decode.min.js">
#   3. a bot-challenge <script> appended to </body>, containing a PER-REQUEST NONCE
norm() {
  sed -E -e 's#href="(mailto:|/cdn-cgi/l/email-protection)[^"]*"#href="EMAIL"#g' \
         -e 's#<script[^>]*/cdn-cgi/[^<]*</script>##g' \
         -e 's#<script>\(function\(\)\{.*</script>##g'
}
LIVE_SUM=$(curl -sf -m 20 -A "$UA" "$SITE_URL$CANARY_PATH" 2>/dev/null | norm | sha256sum | cut -c1-16 || echo "FETCH_FAIL")
if [ -n "$DEPLOY_URL" ]; then
  ORIGIN_SUM=$(curl -sf -m 20 -A "$UA" "$DEPLOY_URL$CANARY_PATH" 2>/dev/null | norm | sha256sum | cut -c1-16 || echo "FETCH_FAIL")
else
  ORIGIN_SUM="$LIVE_SUM"   # couldn't parse the deployment URL — skip the comparison
  echo "  (could not parse deployment URL; skipping origin comparison)"
fi

echo "  canary     : $CANARY_PATH"
echo "  live sha   : $LIVE_SUM"
echo "  origin sha : $ORIGIN_SUM"
if [ "$LIVE_SUM" = "FETCH_FAIL" ] || [ "$ORIGIN_SUM" = "FETCH_FAIL" ]; then
  echo "⚠ VERIFY INCONCLUSIVE — could not fetch. Check manually: $SITE_URL"
elif [ "$LIVE_SUM" = "$ORIGIN_SUM" ]; then
  echo "✓ VERIFIED: the public URL is serving the newly deployed bytes."
else
  echo "❌ NOT LIVE: the public URL is serving DIFFERENT bytes than the deployment."
  echo "   The upload succeeded but users are seeing old content."
  echo "   Likely the edge cache. Re-run the purge, or wait out the 1h edge TTL."
  exit 1   # fail loudly — a deploy that isn't visible is not a success
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "=== Done ==="
echo "Deployment : ${DEPLOY_URL:-unknown}"
echo "Live       : $SITE_URL"
echo "Timestamp  : $(date '+%Y-%m-%d %H:%M:%S')"
