# Google Sheets signup setup

One-time setup (~10 minutes). After this, every pricing form submit appends a row to your sheet and emails you.

## 1. Create the spreadsheet

1. Go to [Google Sheets](https://sheets.google.com) and create a spreadsheet named **Fyndroo Signups**.
2. Open **Extensions → Apps Script**.
3. Delete any default code and paste the contents of `google-apps-script/Code.gs`.
4. Save the project (e.g. name it `Fyndroo Signup Webhook`).

## 2. Script properties

In Apps Script: **Project Settings** (gear) → **Script properties** → Add:

| Property | Value |
| --- | --- |
| `WEBHOOK_SECRET` | A long random string (e.g. `openssl rand -hex 24`) |
| `NOTIFY_EMAIL` | Your email for alerts (e.g. `you@fyndroo.com`) |

Use the **same** `WEBHOOK_SECRET` in Cloudflare (step 4).

## 3. Deploy as web app

1. **Deploy → New deployment**
2. Type: **Web app**
3. Execute as: **Me**
4. Who has access: **Anyone** (required — Cloudflare calls this URL)
5. Deploy and copy the **Web app URL** (ends with `/exec`)

## 4. Cloudflare Pages secrets

From the `fyndroo_website` directory:

```bash
npx wrangler pages secret put GOOGLE_SHEETS_WEBHOOK_URL --project-name=fyndroo-biz
# paste the /exec URL from step 3

npx wrangler pages secret put WEBHOOK_SECRET --project-name=fyndroo-biz
# same value as Script property WEBHOOK_SECRET

# Optional but recommended — Turnstile (Cloudflare dashboard → Turnstile)
npx wrangler pages secret put TURNSTILE_SECRET_KEY --project-name=fyndroo-biz
```

Update `TURNSTILE_SITE_KEY` in `index.html` (search for `TURNSTILE_SITE_KEY`) with your real site key. Until then, the built-in test key works for development.

## 5. Redeploy the site

```bash
./scripts/deploy_cdn.sh
```

## Sheet columns

| Timestamp | Plan | Name | Email | Company | Website | Clients | Message | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

## Test

```bash
curl -X POST https://biz.fyndroo.com/api/signup \
  -H "Content-Type: application/json" \
  -d '{"plan":"pro","name":"Test User","email":"test@example.com","company":"Test Co","website":"test.com"}'
```

Expect `{"ok":true}` and a new sheet row (+ email if `NOTIFY_EMAIL` is set).
