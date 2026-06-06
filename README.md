# fyndroo_website

Fyndroo business landing page — static HTML hosted on Cloudflare Pages at **https://biz.fyndroo.com**.

## Local preview

Open `index.html` in a browser, or:

```bash
python3 -m http.server 8080
# → http://localhost:8080
```

## Deploy to CDN

Same Cloudflare team account as the fyndroo GEO reports project.

```bash
# One-time login
npx wrangler login
npx wrangler whoami   # copy team Account ID if needed

# Deploy (creates/updates Pages project + biz.fyndroo.com)
chmod +x scripts/deploy_cdn.sh
./scripts/deploy_cdn.sh
```

Override defaults:

```bash
export CLOUDFLARE_ACCOUNT_ID=your_team_account_id
CF_PAGES_PROJECT=fyndroo-biz CF_CUSTOM_DOMAIN=biz.fyndroo.com ./scripts/deploy_cdn.sh
```

## Custom domain (biz.fyndroo.com)

Deploy script registers the domain on the Pages project. If DNS is not auto-created (API deploy), add once in Cloudflare:

**DNS** → `fyndroo.com` → **Add record**

| Type | Name | Target | Proxy |
| --- | --- | --- | --- |
| CNAME | `biz` | `fyndroo-biz.pages.dev` | Proxied |

Or: **Workers & Pages** → `fyndroo-biz` → **Custom domains** → confirm `biz.fyndroo.com`.

## Files

| Path | Purpose |
| --- | --- |
| `index.html` | Site root (Fyndroo Business landing page) |
| `wrangler.toml` | Cloudflare Pages config |
| `scripts/deploy_cdn.sh` | Build-less deploy to Pages + custom domain |
