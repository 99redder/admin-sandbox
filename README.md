# admin-sandbox

Standalone admin panel sandbox extracted from `eastern-shore-ai`.

## What this repo contains

- `admin.html` with login, booking controls, tax ledger, accounts, reconciliation, year-end close, audit package, and receipt upload UI
- Cloudflare Worker backend (`worker/`) with matching API routes
- D1 migrations for bookings + accounting/tax tables
- Receipt storage binding (R2)

## Safety intent

This repo is isolated. It has its own:
- Worker name
- D1 database
- R2 receipts bucket
- Admin password secret

Do **not** point this repo at prod `eastern-shore-ai` resources.

## Initial setup

### 1) Create Cloudflare resources

```bash
cd worker
wrangler d1 create admin-sandbox-db
wrangler r2 bucket create admin-sandbox-receipts
```

Copy the returned D1 `database_id` into `worker/wrangler.toml`.

### 2) Apply D1 migrations (remote)

```bash
cd worker
for f in migrations/*.sql; do
  wrangler d1 execute admin-sandbox-db --remote --file "$f"
done
```

### 3) Set secrets/env

```bash
cd worker
wrangler secret put ADMIN_PASSWORD
# optional if using email endpoint features
wrangler secret put RESEND_API_KEY
```

### 4) Deploy worker

```bash
cd worker
wrangler deploy
```

Expected worker URL pattern:
`https://admin-sandbox-contact.<your-subdomain>.workers.dev`

### 5) Connect frontend to worker

`admin.html` defaults to:
`https://admin-sandbox-contact.99redder.workers.dev/api/contact`

If your deployed URL differs, set this globally before the main script (or edit `CONTACT_API_URL`):

```html
<script>
  window.CONTACT_API_URL = 'https://YOUR-WORKER-URL.workers.dev/api/contact';
</script>
```

### 6) GitHub Pages

Publish this repo root via GitHub Pages.

- `index.html` links to `admin.html`
- Use a private/unlisted repo if desired, but remember frontend JS is visible in browser

### 7) CORS allowlist

Update `ALLOWED_ORIGINS` in `worker/wrangler.toml` to your GitHub Pages URL(s), for example:

```toml
ALLOWED_ORIGINS = "https://<user>.github.io,https://<user>.github.io/<repo>"
```

Redeploy after changes:

```bash
cd worker && wrangler deploy
```
