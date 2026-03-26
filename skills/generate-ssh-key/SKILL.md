---
description: Generate an Ed25519 SSH key, add it to the agent, and print the public key
---

Reference: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

## Steps

### 1. Generate the key
```bash
ssh-keygen -t ed25519 -C "claude@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
```

### 2. Start the agent and add the key
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### 3. Print the public key
```bash
cat ~/.ssh/id_ed25519.pub
```

Give the public key to the user and tell them to add it to the service of their choosing.
