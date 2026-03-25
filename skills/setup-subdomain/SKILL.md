---
description: Register a free subdomain under utherbox.com and create an A record for it
---

Use this skill to get a working hostname for a service without needing a custom domain. Available on all tiers.

## Steps

### 1. Get this VM's public IP
```bash
curl -sf https://api.ipify.org
```

### 2. Register the subdomain
```
register_subdomain(label: "<desired-label>")
```
This registers `<label>.utherbox.com` to this project. Returns an error if the label is already taken.

### 3. Create the A record
```
create_dns_record(
  type: "A",
  name: "<label>.utherbox.com",
  content: "<vm-public-ip>",
  ttl: 60,
)
```

### 4. Wait for propagation (usually < 60 seconds)
```bash
watch -n 5 "dig +short A <label>.utherbox.com"
```
Wait until it returns the VM's IP.

### 5. Verify
```bash
curl -sI http://<label>.utherbox.com
```

## Notes
- Subdomain registration is permanent within a project — it survives VM recreation
- Each project can register multiple subdomains
- For HTTPS, run the `setup-tls` skill after DNS propagates
