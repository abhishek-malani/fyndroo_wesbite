#!/usr/bin/env bash
# Deploy Fyndroo business site to Cloudflare Pages (biz.fyndroo.com).
#
# Prerequisites (once):
#   npx wrangler login
#   npx wrangler whoami
#
# account_id is set in wrangler.toml (Koshy.vibin team — same as fyndroo-reports).
#
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="${CF_PAGES_PROJECT:-fyndroo-biz}"
CUSTOM_DOMAIN="${CF_CUSTOM_DOMAIN:-biz.fyndroo.com}"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-5d2bd644d317b5d6ae84292dcf7e9dd0}"
export CLOUDFLARE_ACCOUNT_ID="$ACCOUNT_ID"

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]] && ! npx --yes wrangler whoami >/dev/null 2>&1; then
  echo "==> Cloudflare login (browser — pick Koshy.vibin team if prompted)"
  npx --yes wrangler login
fi

echo "==> Ensuring Pages project: ${PROJECT}"
npx --yes wrangler pages project list 2>/dev/null | grep -q "$PROJECT" || \
  npx --yes wrangler pages project create "$PROJECT" --production-branch=master

echo "==> Building static bundle"
rm -rf dist
mkdir -p dist
cp index.html dist/
if [[ -d functions ]]; then
  cp -r functions dist/functions
  echo "    Included Pages Functions (api/signup)"
fi

echo "==> Deploying dist/ → Pages project: ${PROJECT}"
npx --yes wrangler pages deploy dist \
  --project-name="$PROJECT" \
  --branch=master \
  --commit-dirty=true

echo "==> Attaching custom domain: ${CUSTOM_DOMAIN}"
DOMAIN_JSON=$(python3 <<PY
import json, subprocess, sys, urllib.error, urllib.request

account_id = "${ACCOUNT_ID}"
project = "${PROJECT}"
domain = "${CUSTOM_DOMAIN}"

try:
    raw = subprocess.check_output(["npx", "--yes", "wrangler", "auth", "token", "--json"], text=True)
    token = json.loads(raw).get("token")
    if not token:
        raise RuntimeError("no token from wrangler auth token --json")
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{account_id}/pages/projects/{project}/domains",
        data=json.dumps({"name": domain}).encode(),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        body = json.loads(resp.read().decode())
    if body.get("success"):
        status = (body.get("result") or {}).get("status", "added")
        print(json.dumps({"ok": True, "status": status}))
    else:
        print(json.dumps({"ok": False, "errors": body.get("errors", [])}))
except urllib.error.HTTPError as e:
    body = e.read().decode()
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        parsed = {"message": body}
    print(json.dumps({"ok": False, "errors": parsed.get("errors", [parsed])}))
except Exception as e:
    print(json.dumps({"ok": False, "errors": [{"message": str(e)}]}))
PY
)

if echo "$DOMAIN_JSON" | grep -q '"ok": true'; then
  STATUS=$(echo "$DOMAIN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','added'))")
  echo "    Custom domain ${CUSTOM_DOMAIN} (${STATUS})."
else
  echo "    Add ${CUSTOM_DOMAIN} in Cloudflare Dashboard:"
  echo "    Workers & Pages → ${PROJECT} → Custom domains → Set up a custom domain"
  echo "    API response: $DOMAIN_JSON"
fi

echo ""
echo "Done."
echo "  Pages:  https://${PROJECT}.pages.dev/"
echo "  Live:   https://${CUSTOM_DOMAIN}/"
