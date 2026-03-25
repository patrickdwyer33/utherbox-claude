---
description: Install nginx with HTTPS for a web application
---

## Steps

### 1. Install nginx
```bash
sudo apt-get update && sudo apt-get install -y nginx
sudo systemctl enable nginx
```

### 2. Write server block
```bash
sudo tee /etc/nginx/sites-available/<domain> > /dev/null << 'EOF'
server {
    listen 80;
    server_name <domain>;
    # Redirect HTTP → HTTPS after cert is issued
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
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
sudo ln -sf /etc/nginx/sites-available/<domain> /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 3. Issue TLS certificate
Use the `setup-tls` skill. nginx must be stopped first (acme.sh needs port 80):
```bash
sudo systemctl stop nginx
```
Run `setup-tls` skill, then continue.

### 4. Test and reload
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 5. Verify
```bash
curl -sI https://<domain> | head -3
```

## Security notes
- `ssl_protocols TLSv1.2 TLSv1.3` — disables TLS 1.0/1.1
- Proxy passes `X-Forwarded-Proto` so apps can detect HTTPS
- Default site removed to prevent unintended fallthrough
