---
description: Use when setting up any dev server, preview server, brainstorming tool, or any service you or the user would normally access at localhost. On this VM, localhost is not reachable by the user — expose it via public IP instead.
---

## Rule

**Never point the user to `localhost` or `127.0.0.1`.** This VM is remote. The user accesses it over the network. Always give them a `http://PUBLIC_IP:PORT` (or HTTPS) URL.

## Steps

### 1. Get the public IP
```bash
PUBLIC_IP=$(curl -sf https://api.ipify.org)
echo "Public IP: $PUBLIC_IP"
```

### 2. Start the dev server bound to all interfaces

Most frameworks default to `127.0.0.1` — override this:

**Vite / Vite-based (SvelteKit, Astro, etc.):**
```bash
npx vite --host 0.0.0.0 --port 5173
```

**Next.js:**
```bash
npx next dev -H 0.0.0.0 -p 3000
```

**Create React App:**
```bash
HOST=0.0.0.0 npm start
```

**Node / Express / Fastify:**
```js
app.listen(3000, '0.0.0.0')
```

**Python (Flask):**
```bash
flask run --host=0.0.0.0 --port=5000
```

**Python (uvicorn / FastAPI):**
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 3. Tell the user the URL

```
Access it at: http://$PUBLIC_IP:<PORT>
```

Paste the URL directly — don't say "localhost".

---

## Optional: nginx reverse proxy

Use nginx if you want a clean port (80) or HTTPS without changing how the app runs.

### Nginx HTTP proxy (port 80 → app port)
```bash
sudo apt-get install -y nginx
sudo tee /etc/nginx/sites-available/dev > /dev/null << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:<APP_PORT>;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        # For websockets (HMR, live reload):
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/dev /etc/nginx/sites-enabled/dev
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

User accesses: `http://$PUBLIC_IP`

---

## Optional: HTTPS with a self-signed certificate (no domain required)

Let's Encrypt requires a domain. For IP-only HTTPS, generate a self-signed cert with an IP SAN:

```bash
PUBLIC_IP=$(curl -sf https://api.ipify.org)
sudo mkdir -p /etc/ssl/dev
sudo openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/ssl/dev/key.pem \
  -out /etc/ssl/dev/cert.pem \
  -days 365 -nodes \
  -subj "/CN=$PUBLIC_IP" \
  -addext "subjectAltName=IP:$PUBLIC_IP"
```

Then add to the nginx block:
```nginx
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate     /etc/ssl/dev/cert.pem;
    ssl_certificate_key /etc/ssl/dev/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://127.0.0.1:<APP_PORT>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

User accesses: `https://$PUBLIC_IP` (browser will warn once about the self-signed cert — click through to proceed)

---

## Notes

- Linode VMs have no firewall by default — ports are reachable immediately without extra rules.
- WebSocket / HMR (hot module reload): the `Upgrade` + `Connection` headers in the nginx config above are required; without them, live reload will silently fail.
- Self-signed HTTPS is fine for dev/brainstorming. If the user needs a trusted cert, they need a domain — use the `setup-subdomain` + `setup-tls` skills.
