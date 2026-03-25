---
description: Install Docker Engine and Compose plugin
---

## Steps

### 1. Install Docker Engine from official repo
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2. Add claude to docker group (avoids sudo for docker commands)
```bash
sudo usermod -aG docker claude
newgrp docker   # or log out and back in
```

### 3. Enable and verify
```bash
sudo systemctl enable --now docker
docker run --rm hello-world
docker compose version
```

## Notes
- `docker compose` (v2, plugin) is installed; `docker-compose` (v1, standalone) is not
- The `newgrp docker` only affects the current shell. A fresh SSH session will have the group applied automatically.
