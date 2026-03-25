---
description: Check domain availability and guide through purchasing a domain on Cloudflare Registrar
---

Domain registration is done manually by the user. Use this skill to guide them through the process.

## Steps

### 1. Check availability

Use the `check-availability` skill (or run `scripts/check-availability.sh <domain>` directly):

```bash
~/utherbox-claude/scripts/check-availability.sh <domain>
```

- Exit 0 + "AVAILABLE" → proceed
- Exit 1 + "TAKEN" → suggest alternatives (different TLD, name variant)
- Exit 2 → RDAP lookup error; try again or check internet connectivity

### 2. If available — guide purchase

> "**`<domain>` is available.** To purchase it:
>
> 1. Go to **dash.cloudflare.com → Domain Registration → Register Domains**
> 2. Search for `<domain>` and click **Purchase**
> 3. Complete registration (typically $8–15/year for `.com`)
> 4. The domain's DNS zone will appear in your Cloudflare account automatically
>
> Once purchased, come back and I can:
> - Link the zone to this workspace (`setup-cloudflare` skill)
> - Issue a TLS certificate"

### 3. After purchase

If the user has purchased and wants to proceed:
- Run `setup-cloudflare` skill to link the zone
- Run `manage-dns` skill to create DNS records
- Run `setup-tls` skill after DNS propagates

## Notes
- Do not call `buy_domain` — the platform endpoint returns 501 (not implemented)
- RDAP availability check has a built-in 50–300ms delay; this is intentional (anti-sniping)
