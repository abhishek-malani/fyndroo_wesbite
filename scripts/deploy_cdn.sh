#!/usr/bin/env bash
# Deploy Fyndroo business site to Cloudflare Pages (biz.fyndroo.com).
#
# Prerequisites (once):
#   npx wrangler login
#   npx wrangler whoami
#   export CLOUDFLARE_ACCOUNT_ID=<team_account_id>
#
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="${CF_PAGES_PROJECT:-fyndroo-biz}"
CUSTOM_DOMAIN="${CF_CUSTOM_DOMAIN:-biz.fyndroo.com}"

export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-5d2bd644d317b5d6ae84292dcf7e9dd0}"

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]] && ! npx --yes wrangler whoami >/dev/null 2>&1; then
  echo "==> Cloudflare login (browser — pick team account if prompted)"
  npx --yes wrangler login
fi

ACCOUNT_ARGS=()
if [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
  ACCOUNT_ARGS=(--account-id "$CLOUDFLARE_ACCOUNT_ID")
  echo "==> Using CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID}"
fi

echo "==> Ensuring Pages project: ${PROJECT}"
npx --yes wrangler pages project list 2>/dev/null | grep -q "$PROJECT" || \
  npx --yes wrangler pages project create "$PROJECT" --production-branch=master \
    "${ACCOUNT_ARGS[@]}"

echo "==> Deploying site root → Pages project: ${PROJECT}"
npx --yes wrangler pages deploy . \
  "${ACCOUNT_ARGS[@]}" \
  --project-name="$PROJECT" \
  --branch=master \
  --commit-dirty=true

echo "==> Attaching custom domain: ${CUSTOM_DOMAIN}"
if npx --yes wrangler pages project domain list "$PROJECT" "${ACCOUNT_ARGS[@]}" 2>/dev/null | grep -q "$CUSTOM_DOMAIN"; then
  echo "    Domain already configured."
else
  npx --yes wrangler pages project domain add "$CUSTOM_DOMAIN" \
    "${ACCOUNT_ARGS[@]}" \
    --project-name="$PROJECT" || echo "    (Add ${CUSTOM_DOMAIN} manually in Cloudflare dashboard if this step failed.)"
fi

echo ""
echo "Done."
echo "  Pages:  https://${PROJECT}.pages.dev/"
echo "  Live:   https://${CUSTOM_DOMAIN}/"
