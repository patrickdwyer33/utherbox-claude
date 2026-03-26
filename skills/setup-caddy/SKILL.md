---
description: Install Caddy web server with automatic TLS
---

Caddy handles TLS automatically via ACME. Use only when the user specifically requests Caddy — nginx is the platform default (use `setup-nginx` skill instead).

## Steps

### 1. Install Caddy from official repo
```bash
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update && sudo apt-get install -y caddy
```

### 2. Write Caddyfile
```bash
sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
<domain> {
    reverse_proxy 127.0.0.1:<app-port>
}
EOF
```

### 3. Enable and start
```bash
sudo systemctl enable --now caddy
```
Caddy fetches the TLS certificate automatically on first request. Ensure the domain's A record points to this VM's IP before starting.

### 4. Verify
```bash
sudo systemctl status caddy
curl -sI https://<domain> | head -1
```

## Notes
- Caddy stores certs in `/var/lib/caddy/.local/share/caddy/`
- To reload after Caddyfile changes: `sudo systemctl reload caddy`
- Rate limit protection: Caddy uses Let's Encrypt by default; first-time cert acquisition may take 30–60 seconds
