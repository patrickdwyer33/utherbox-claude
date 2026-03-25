---
description: Check whether a domain name is available for registration using RDAP
---

## How to use

```bash
~/utherbox-claude/scripts/check-availability.sh <domain>
```

- **Exit 0** — domain is available. Proceed with purchase guidance (`domain-purchase` skill).
- **Exit 1** — domain is registered. Output includes registrar and expiry if known.
- **Exit 2** — lookup error (bad domain format or network issue).

## Examples

```bash
# Check a .com
~/utherbox-claude/scripts/check-availability.sh myapp.com

# Check a .dev
~/utherbox-claude/scripts/check-availability.sh myapp.dev
```

## Notes
- Uses ICANN RDAP (rdap.org) — authoritative and registrar-neutral
- Works for any domain regardless of Cloudflare configuration
- No credentials needed — pure DNS/RDAP lookup
- For purchase guidance, use the `domain-purchase` skill after confirming availability
