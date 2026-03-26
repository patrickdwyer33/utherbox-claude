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

### 4. Choose issuance mode

**Prefer webroot mode** when a web server is already installed — it's simpler and more reliable.

**Standalone mode** uses socat to listen on port 80. This fails when running as a non-root user (e.g. `claude`) because port 80 is privileged. Use `sudo` to run acme.sh in standalone mode, or use webroot mode instead.

Check if nginx or caddy is installed:
```bash
command -v nginx || command -v caddy
```

**If a web server is installed → use webroot mode (recommended):**

1. Ensure it's running on port 80 (even a minimal config is fine):
```bash
# For nginx: create a minimal config if needed
echo 'server { listen 80; server_name <domain>; root /var/www/<domain>; }' \
  | sudo tee /etc/nginx/sites-available/<domain> > /dev/null
sudo ln -sf /etc/nginx/sites-available/<domain> /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl start nginx
```

2. Create the webroot directory:
```bash
sudo mkdir -p /var/www/<domain>
sudo chown $(whoami):$(whoami) /var/www/<domain>
```

3. Issue the certificate:
```bash
~/.acme.sh/acme.sh --issue -d <domain> --webroot /var/www/<domain> --server letsencrypt
```

**If no web server is installed → use standalone mode:**

Standalone requires either root or sudo because socat must bind to port 80 (privileged).

1. Ensure port 80 is free:
```bash
sudo ss -tlnp | grep :80
# If something is listening, stop it first
```

2. Issue the certificate (note `sudo`):
```bash
sudo ~/.acme.sh/acme.sh --issue -d <domain> --standalone --server letsencrypt
```

If you omit `sudo`, socat will fail with "Permission denied" or "Connection refused."

### 5. Install to /etc/ssl/
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

### 6. Restart the web server
```bash
sudo systemctl start nginx 2>/dev/null || sudo systemctl start caddy 2>/dev/null || true
```

### 7. Verify
```bash
curl -sI https://<domain> | head -1
```
Expected: `HTTP/2 200` or similar. If you see a certificate error, check `/var/log/nginx/error.log` or `journalctl -u caddy`.

## Error handling

- **"Connection refused" or "Permission denied" in standalone mode** — socat can't bind to port 80 without root. Use `sudo ~/.acme.sh/acme.sh --standalone ...` or switch to webroot mode with nginx/caddy.
- **Rate limited by Let's Encrypt** — acme.sh will surface this. Wait before retrying. For testing, use `--server letsencrypt_test` (produces untrusted cert but avoids rate limits).
- **DNS not yet propagated** — wait and retry. `dig @8.8.8.8 +short A <domain>` to check from Google's resolver.
- **Port 80 blocked by firewall** — if on a cloud provider, check security group / firewall rules. Linode VMs have no firewall by default.
