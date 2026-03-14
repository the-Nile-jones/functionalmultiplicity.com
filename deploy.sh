#!/bin/bash
# deploy.sh — deploy functionalmultiplicity.com + backup live copy to ClickUp
# Usage: bash /home/nile/nile-protocol-pages/deploy.sh

set -e

SITE_URL="https://functionalmultiplicity.com"
CLICKUP_WORKSPACE="9017919084"
CLICKUP_DOC_ID="8cr51kc-1917"
CLICKUP_PAGE_ID="8cr51kc-4077"
GCP_PROJECT="popos-and-mcp"
SCRIPT_DIR="$(dirname "$0")"

echo "=== FM Deploy Pipeline ==="
echo "$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ── 1. Cloudflare token ───────────────────────────────────────────────────────
# grep bypasses the interactive-shell guard in /root/.bashrc
CLOUDFLARE_API_TOKEN=$(grep -oP '(?<=CLOUDFLARE_API_TOKEN=)\S+' /root/.bashrc 2>/dev/null || true)
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "ERROR: CLOUDFLARE_API_TOKEN not found in /root/.bashrc"
  exit 1
fi
echo "✓ Cloudflare token loaded"

# ── 2. ClickUp API key from GSM ───────────────────────────────────────────────
echo "Fetching ClickUp API key from GSM..."
CLICKUP_API_KEY=$(gcloud secrets versions access latest \
  --secret=CLICK_UP_API \
  --project="$GCP_PROJECT" 2>/dev/null || true)
if [ -z "$CLICKUP_API_KEY" ]; then
  echo "ERROR: Could not fetch CLICK_UP_API from GSM"
  echo "       Run: gcloud auth login  (on aiserver)"
  exit 1
fi
echo "✓ ClickUp API key loaded"
echo ""

# ── 3. Wrangler deploy ────────────────────────────────────────────────────────
echo "Deploying to Cloudflare Workers..."
cd "$SCRIPT_DIR"
DEPLOY_OUTPUT=$(CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" npx wrangler deploy 2>&1)
echo "$DEPLOY_OUTPUT"
VERSION_ID=$(echo "$DEPLOY_OUTPUT" | grep -oP '(?<=Current Version ID: )\S+' || echo "unknown")
echo ""

# ── 4. Fetch live site + convert to markdown ──────────────────────────────────
echo "Fetching live site for ClickUp backup..."
sleep 4
LIVE_HTML=$(curl -sf "$SITE_URL")
TODAY=$(date '+%Y-%m-%d')
LIVE_MD=$(echo "$LIVE_HTML" | python3 "$SCRIPT_DIR/html_to_md.py" "$TODAY")
echo "✓ Site fetched and converted"

# ── 5. Update ClickUp live copy doc ──────────────────────────────────────────
echo "Updating ClickUp live copy doc..."
PAYLOAD=$(python3 -c "import json, sys; print(json.dumps({'content': sys.stdin.read(), 'content_format': 'text/md'}))" <<< "$LIVE_MD")

HTTP_CODE=$(curl -s -o /tmp/clickup_response.json -w "%{http_code}" \
  -X PUT \
  "https://api.clickup.com/api/v3/workspaces/$CLICKUP_WORKSPACE/docs/$CLICKUP_DOC_ID/pages/$CLICKUP_PAGE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "✓ ClickUp live copy updated (HTTP $HTTP_CODE)"
else
  echo "⚠ ClickUp update returned HTTP $HTTP_CODE"
  cat /tmp/clickup_response.json
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=== Done ==="
echo "Version ID : $VERSION_ID"
echo "ClickUp doc: $CLICKUP_DOC_ID / page $CLICKUP_PAGE_ID"
echo "Timestamp  : $(date '+%Y-%m-%d %H:%M:%S')"
