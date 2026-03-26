---
description: Install nginx with HTTPS for a web application
---

## Steps

### 1. Install nginx
```bash
sudo apt-get update && sudo apt-get install -y nginx
sudo systemctl enable nginx
```

### 2. Write HTTP-only server block (for TLS issuance)

Start with an HTTP-only config so nginx is serving on port 80 when acme.sh runs. The HTTPS block gets added after the cert is issued.

```bash
sudo mkdir -p /var/www/<domain>
sudo chown $(whoami):$(whoami) /var/www/<domain>

sudo tee /etc/nginx/sites-available/<domain> > /dev/null << 'EOF'
server {
    listen 80;
    server_name <domain>;
    root /var/www/<domain>;
    location / { try_files $uri $uri/ =404; }
}
EOF
sudo ln -sf /etc/nginx/sites-available/<domain> /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl start nginx
```

### 3. Issue TLS certificate

Use the `setup-tls` skill with **webroot mode** (nginx stays running — no need to stop it):
```bash
~/.acme.sh/acme.sh --issue -d <domain> --webroot /var/www/<domain> --server letsencrypt
```

**Do NOT stop nginx** for cert issuance. The old pattern of stopping nginx and using `--standalone` has a race condition where socat fails to bind before Let's Encrypt validates. Webroot mode avoids this entirely.

### 4. Install the certificate
```bash
sudo mkdir -p /etc/ssl/<domain>
~/.acme.sh/acme.sh --install-cert -d <domain> \
  --cert-file /etc/ssl/<domain>/cert.pem \
  --key-file /etc/ssl/<domain>/key.pem \
  --fullchain-file /etc/ssl/<domain>/fullchain.pem \
  --reloadcmd "systemctl reload nginx 2>/dev/null || true"
sudo chmod 644 /etc/ssl/<domain>/cert.pem /etc/ssl/<domain>/fullchain.pem
sudo chmod 600 /etc/ssl/<domain>/key.pem
sudo chown root:root /etc/ssl/<domain>/*.pem
```

### 5. Update nginx config with HTTPS

Replace the HTTP-only config with the full HTTP→HTTPS redirect + SSL config:

```bash
sudo tee /etc/nginx/sites-available/<domain> > /dev/null << 'EOF'
server {
    listen 80;
    server_name <domain>;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name <domain>;

    ssl_certificate     /etc/ssl/<domain>/fullchain.pem;
    ssl_certificate_key /etc/ssl/<domain>/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:<app-port>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

For static sites (SPA), replace the `proxy_pass` location block with:
```nginx
    root /var/www/<domain>;
    index index.html;
    location / { try_files $uri $uri/ /index.html; }
```

### 6. Test and reload
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 7. Verify
```bash
curl -sI https://<domain> | head -3
```

## Security notes
- `ssl_protocols TLSv1.2 TLSv1.3` — disables TLS 1.0/1.1
- Proxy passes `X-Forwarded-Proto` so apps can detect HTTPS
- Default site removed to prevent unintended fallthrough
