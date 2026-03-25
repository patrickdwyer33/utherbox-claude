---
description: Deploy or update an application from a git repository
---

## Steps

### 1. Clone (first deploy) or pull (update)
```bash
# First deploy:
git clone <repo-url> ~/app
# Or update:
cd ~/app && git pull
```

### 2. Build (language-aware)

**Node.js:**
```bash
cd ~/app && npm ci && npm run build
```

**Python:**
```bash
cd ~/app && pip install -r requirements.txt
```

**Go:**
```bash
cd ~/app && go build -o bin/app ./...
```

### 3. Restart gracefully

**If using systemd** (preferred for production):
```bash
# Create service if not exists:
sudo tee /etc/systemd/system/app.service > /dev/null << 'EOF'
[Unit]
Description=App
After=network.target

[Service]
Type=simple
User=claude
WorkingDirectory=/home/claude/app
ExecStart=/home/claude/app/bin/app   # or: node dist/index.js, python3 app.py, etc.
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now app
# Update only:
sudo systemctl restart app
```

**If using pm2:**
```bash
# First deploy:
npm install -g pm2
pm2 start dist/index.js --name app
pm2 save
pm2 startup | tail -1 | bash  # set up autostart
# Update only:
pm2 restart app
```

### 4. Verify
```bash
sudo systemctl status app   # or: pm2 status
curl -s http://localhost:<port>/health
```

## Error handling
- **Build fails**: check error output, fix, commit, pull again
- **Service fails to start**: `journalctl -u app -n 50` or `pm2 logs app --lines 50`
- **Port conflict**: `ss -tlnp | grep :<port>` to find what's occupying the port
