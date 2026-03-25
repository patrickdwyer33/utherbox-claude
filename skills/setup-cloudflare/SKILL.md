---
description: Link a Cloudflare API token and zone to this account for DNS management
---

Use this skill when the user wants to manage DNS for their own domain. Required before `manage-dns` or `setup-tls` on a custom domain.

## Steps

### 1. Explain what's needed

Tell the user: "To manage DNS for your domain, I need a Cloudflare API token with Zone:DNS:Edit permission and your zone ID."

### 2. Guide them to create a token

> 1. Go to **dash.cloudflare.com → My Profile → API Tokens**
> 2. Click **Create Token**
> 3. Use the **Edit zone DNS** template
> 4. Under **Zone Resources**, select your specific domain zone
> 5. Click **Continue to summary → Create Token**
> 6. Copy the token — shown only once

### 3. Guide them to find their Zone ID

> 1. Go to the zone's overview page in the Cloudflare dashboard
> 2. Scroll down the right sidebar — **Zone ID** is there (32 hex characters)

### 4. Link it using the MCP tool

```
link_cloudflare(
  cf_api_token: "<their-token>",
  cf_zone_id: "<their-zone-id>",
)
```

### 5. Verify it worked

```
list_dns_records()
```

If this returns records (or an empty array), the link is working.

## Notes

- The token is stored encrypted on the platform server — it never touches the VM's disk
- Linking takes effect immediately; no re-provisioning needed
- If the token expires, repeat this process to update it
