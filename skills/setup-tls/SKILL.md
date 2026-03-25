---
description: Issue a TLS certificate for a domain pointing at this VM using acme.sh (HTTP-01)
---

Use this skill whenever a domain needs a TLS certificate. Requires the domain's A record to already point to this VM's public IP.

## Steps

### 1. Get this VM's public IP
```bash
curl -sf https://api.ipify.org
```

### 2. Verify the A record points here
```bash
dig +short A <domain>
```
If the IP does not match, fix DNS first (use `setup-subdomain` or `manage-dns` skill). Do not proceed until DNS resolves correctly — acme.sh will fail and hit rate limits.

### 3. Install acme.sh (if not present)
```bash
if [ ! -f ~/.acme.sh/acme.sh ]; then
  curl -fsSL https://get.acme.sh | bash -s email=admin@$(hostname -f)
  source ~/.bashrc
fi
```

### 4. Ensure port 80 is open
acme.sh HTTP-01 requires port 80 to be reachable. Check if nginx/caddy is already running:
```bash
ss -tlnp | grep :80
```
If something is already listening on 80, stop it temporarily:
```bash
sudo systemctl stop nginx 2>/dev/null || sudo systemctl stop caddy 2>/dev/null || true
```

### 5. Issue the certificate
```bash
~/.acme.sh/acme.sh --issue -d <domain> --standalone --server letsencrypt
```

### 6. Install to /etc/ssl/
```bash
sudo mkdir -p /etc/ssl/<domain>
~/.acme.sh/acme.sh --install-cert -d <domain> \
  --cert-file /etc/ssl/<domain>/cert.pem \
  --key-file /etc/ssl/<domain>/key.pem \
  --fullchain-file /etc/ssl/<domain>/fullchain.pem \
  --reloadcmd "systemctl reload nginx 2>/dev/null || systemctl reload caddy 2>/dev/null || true"
sudo chmod 644 /etc/ssl/<domain>/cert.pem /etc/ssl/<domain>/fullchain.pem
sudo chmod 600 /etc/ssl/<domain>/key.pem
sudo chown root:root /etc/ssl/<domain>/*.pem
```

### 7. Restart the web server
```bash
sudo systemctl start nginx 2>/dev/null || sudo systemctl start caddy 2>/dev/null || true
```

### 8. Verify
```bash
curl -sI https://<domain> | head -1
```
Expected: `HTTP/2 200` or similar. If you see a certificate error, check `/var/log/nginx/error.log` or `journalctl -u caddy`.

## Error handling

- **Rate limited by Let's Encrypt** — acme.sh will surface this. Wait before retrying. For testing, use `--server letsencrypt_test` (produces untrusted cert but avoids rate limits).
- **DNS not yet propagated** — wait and retry. `dig @8.8.8.8 +short A <domain>` to check from Google's resolver.
- **Port 80 blocked by firewall** — if on a cloud provider, check security group / firewall rules. Linode VMs have no firewall by default.
