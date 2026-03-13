#!/bin/bash
# deploy.sh — one-command deploy for functionalmultiplicity.com
# Uses CLOUDFLARE_API_TOKEN from environment (set in /root/.bashrc)

set -e

# Try GCE metadata first (if running on a GCE VM), fall back to env var
if curl -sf --connect-timeout 2 -H 'Metadata-Flavor: Google' \
    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token > /dev/null 2>&1; then
  echo "Fetching token from GSM via GCE metadata..."
  GCP_TOKEN=$(curl -sf -H 'Metadata-Flavor: Google' \
    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
  CLOUDFLARE_API_TOKEN=$(curl -sf -H "Authorization: Bearer $GCP_TOKEN" \
    "https://secretmanager.googleapis.com/v1/projects/popos-and-mcp/secrets/CLOUDFLARE_CUSTOM_API/versions/latest:access" \
    | python3 -c 'import json,sys,base64; print(base64.b64decode(json.load(sys.stdin)["payload"]["data"]).decode())')
else
  echo "Using token from environment..."
  if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    source /root/.bashrc
  fi
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "ERROR: No Cloudflare token found."
  exit 1
fi

echo "Deploying..."
cd "$(dirname "$0")"
CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" npx wrangler deploy

echo "Done."
