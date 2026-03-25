---
description: Create, update, or delete DNS records (tier-aware)
---

## Before starting: check tier

```
get_limits()
```

Look at `allowed_instance_categories` — if the user is on the **Light tier** (only `nanode` allowed), they can only manage records under their owned `utherbox.com` subdomains. **Bespoke and Premium** tiers can manage records across their full Cloudflare zone.

## Light tier (utherbox.com subdomains only)

Register a subdomain first if needed (use `setup-subdomain` skill), then:

```
create_dns_record(
  type: "A",
  name: "<label>.utherbox.com",
  content: "<ip>",
  ttl: 60,
)
```

## Bespoke/Premium tier (full CF zone)

If Cloudflare is not linked yet, use the `setup-cloudflare` skill first.

### List existing records
```
list_dns_records()
```

### Create a record
```
create_dns_record(
  type: "A",
  name: "<subdomain>.<domain>",
  content: "<ip>",
  ttl: 1,          # 1 = automatic (recommended)
  proxied: false,  # true to route through Cloudflare proxy
)
```

### Update a record
Use `record_id` from `list_dns_records()`:
```
update_dns_record(
  record_id: "<id>",
  type: "A",
  name: "<subdomain>.<domain>",
  content: "<new-ip>",
)
```

### Delete a record
```
delete_dns_record(record_id: "<id>")
```

## Common record types

| Type | Use case | `content` example |
|------|----------|-------------------|
| A | Point hostname to IPv4 | `1.2.3.4` |
| AAAA | Point hostname to IPv6 | `2001:db8::1` |
| CNAME | Alias to another hostname | `myapp.onrender.com` |
| MX | Mail server | `mail.example.com` |
| TXT | Verification, SPF, DKIM | `v=spf1 include:... ~all` |
