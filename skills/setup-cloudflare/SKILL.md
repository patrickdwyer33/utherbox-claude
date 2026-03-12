---
description: Guide the user through linking a Cloudflare account to their Utherbox workspace
---

Your DNS and certificate tools require a Cloudflare account with DNS edit permission.
The user's workspace does not have Cloudflare configured yet (or the token has expired).

## When This Applies

- Any `list_dns_records`, `create_dns_record`, `delete_dns_record`, or `get_acme_cert`
  tool call fails with "Cloudflare is not configured"
- The user asks to set up DNS, get a TLS certificate, or manage their domain
- The user asks how to connect their Cloudflare account

## What To Do

1. **Explain** — tell the user that DNS and TLS certificate tools require a Cloudflare API token
   with `Zone:DNS:Edit` permission for their domain's zone.

2. **Guide them to create a token:**

   > 1. Go to **dash.cloudflare.com → My Profile → API Tokens**
   > 2. Click **Create Token**
   > 3. Use the **Edit zone DNS** template (or create custom with `Zone:DNS:Edit` permission)
   > 4. Under **Zone Resources**, select the specific zone (domain) this workspace will manage
   > 5. Click **Continue to summary → Create Token**
   > 6. Copy the token — it will only be shown once

3. **Guide them to find their Zone ID:**

   > 1. Go to the zone's overview page in the Cloudflare dashboard
   > 2. Scroll down the right sidebar — the **Zone ID** is listed there
   > 3. Copy it (it looks like: `abc123def456...` — 32 hex characters)

4. **Guide them to link it to the platform:**

   > Call `POST /cloudflare/link` on the Utherbox platform API with:
   > ```json
   > {
   >   "cf_api_token": "<your token>",
   >   "cf_zone_id": "<your zone ID>"
   > }
   > ```
   > Include your platform `Authorization: Bearer <token>` header.

5. **Important:** After linking, the user must **re-provision this workspace** (delete and
   recreate the project) for the new CF credentials to take effect. Credentials are embedded
   at VM boot time and cannot be updated on a running VM.

   > "Once you've linked your Cloudflare account, you'll need to delete and recreate this
   > workspace so the new credentials are picked up during setup."

6. **If the user cannot or does not want to re-provision now** — note which DNS/cert tasks
   are blocked, record them in `~/CLAUDE.md`, and continue with any work that does not
   require DNS.
