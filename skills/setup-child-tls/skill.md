---
description: Issue a TLS certificate for a child VM via SSH using acme.sh HTTP-01
---

## Prerequisites

Collect before starting. Ask the user for anything missing:

| # | What | Notes |
|---|------|-------|
| 1 | **Child VM IP** | public IPv4 |
| 2 | **Subdomain** | `{name}.utherbox.com` — must be registered via `register_subdomain` first |
| 3 | **DNS resolving** | `dig +short {subdomain}.utherbox.com` must return the VM's IP |
| 4 | **SSH access** | typically `root@{ip}` |

If subdomain not yet registered: do that first, then wait ~1–2 min for Cloudflare propagation before issuing the cert.

## Reload Command

If the user tells you which web server they're running, use its reload command. Otherwise use the auto-detect default.

| Web server | `--reloadcmd` |
|------------|---------------|
| User-specified | use what they say |
| nginx | `systemctl reload nginx` |
| caddy | `systemctl reload caddy` |
| apache2 | `systemctl reload apache2` |
| haproxy | `systemctl reload haproxy` |
| traefik | `systemctl restart traefik` |
| unknown | `systemctl reload nginx \|\| systemctl reload caddy \|\| systemctl reload apache2 \|\| systemctl reload haproxy \|\| true` |

## Steps

**1. Open firewall ports**
```bash
ssh root@{ip} "ufw allow 80/tcp && ufw allow 443/tcp"
```

**2. Install acme.sh**
```bash
ssh root@{ip} "curl https://get.acme.sh | sh -s email=certs@utherbox.com"
```
Installs to `/root/.acme.sh/`, sets up daily renewal cron.

**3. Issue cert (standalone HTTP-01)**
```bash
ssh root@{ip} "/root/.acme.sh/acme.sh --issue -d {subdomain}.utherbox.com --standalone --server letsencrypt"
```
acme.sh starts its own HTTP server on port 80 for the challenge — no web server needed.

**4. Install to standard path**
```bash
ssh root@{ip} "
  mkdir -p /etc/ssl/{subdomain}.utherbox.com &&
  /root/.acme.sh/acme.sh --install-cert -d {subdomain}.utherbox.com \
    --cert-file      /etc/ssl/{subdomain}.utherbox.com/cert.pem \
    --key-file       /etc/ssl/{subdomain}.utherbox.com/key.pem \
    --fullchain-file /etc/ssl/{subdomain}.utherbox.com/fullchain.pem \
    --reloadcmd      '{reloadcmd}'
"
```

**5. Update VM registry**

If this VM is registered in `~/utherbox-vms/{name}/`, append to `## History`:
```
- {YYYY-MM-DD}: TLS issued for {subdomain}.utherbox.com
```
And add/update a `cert:` line in the header block:
```
cert: /etc/ssl/{subdomain}.utherbox.com
```

**6. Tell the user**

> TLS certificate issued for `{subdomain}.utherbox.com`:
> - `/etc/ssl/{subdomain}.utherbox.com/cert.pem`
> - `/etc/ssl/{subdomain}.utherbox.com/key.pem`
> - `/etc/ssl/{subdomain}.utherbox.com/fullchain.pem`
>
> Auto-renews via cron. To update the reload command later, re-run `--install-cert` with a new `--reloadcmd` — no need to re-issue.

## Troubleshooting

- **Port 80 in use:** stop the conflicting process before `--issue`, or use `--webroot` if a web server is running with a known document root
- **DNS not propagated:** acme.sh will return an authorization error — verify with `dig` and retry
- **acme.sh not found:** always use the full path `/root/.acme.sh/acme.sh` to avoid shell reload issues
