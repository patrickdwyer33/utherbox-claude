---
description: Guide the user through checking domain availability and purchasing it on Cloudflare
---

Domain registration cannot be automated via the Utherbox platform. Use this skill whenever
the user wants to acquire a domain name.

## What To Do

1. **Check availability first** — use the `check_availability` tool:
   ```
   check_availability(domain: "theirdomain.com")
   ```
   This queries ICANN RDAP authoritatively. A 404 means the domain is unregistered (available).

2. **If available** — guide the user to purchase it manually on Cloudflare:

   > "**`theirdomain.com` is available.** To purchase it:
   >
   > 1. Go to **dash.cloudflare.com → Domain Registration → Register Domains**
   > 2. Search for `theirdomain.com` and click **Purchase**
   > 3. Complete the registration (price varies by TLD, typically $8–15/year for `.com`)
   > 4. Once registered, the domain's DNS zone will appear in your Cloudflare account
   >
   > After purchasing, come back here and I can help you:
   > - Link the zone to this workspace (so I can manage DNS records)
   > - Issue a TLS certificate for the domain"

3. **If not available** — tell the user the domain is already registered and suggest alternatives:
   - Try a different TLD (`.net`, `.dev`, `.io`, etc.) using `check_availability` again
   - Try a variant of the name

4. **After purchase** — if the user has already purchased the domain and linked their
   Cloudflare account, proceed with DNS and certificate setup using the available tools.
   If not yet linked, use the `setup-cloudflare` skill to guide them through that step first.

## Notes

- Do NOT call `buy_domain` or `transfer_in` tools — these endpoints return 501 and are not implemented.
- The RDAP check has a built-in 50–300ms anti-sniping delay; this is intentional.
- `check_availability` works for any domain regardless of CF configuration.
