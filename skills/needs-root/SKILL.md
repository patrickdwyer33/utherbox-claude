---
description: Handle tasks requiring root or sudo by offering to migrate work to a child VM
---

No sudo access on this VM. Follow this flow exactly.

## Triggers

`sudo`, root access, system package install, port < 1024, writing to system paths, kernel/system config changes.

## Flow

| Step | Action |
|------|--------|
| 1 | **Stop** — do not attempt the root-requiring action |
| 2 | **Ask the user** — state specifically what needs root, then ask if they want a child VM |
| 3 | **User declines** → drop the root approach entirely, discuss alternatives, do not provision |
| 4 | **User confirms** → provision, migrate, continue (see below) |

## If User Confirms: Migration Steps

1. Provision child VM via `create_vm` (vm-mcp)
2. SSH in as root
3. Reconstruct context: clone repos, copy in-progress files
4. Continue all subsequent work from the child VM — treat it as the new base unless the user says otherwise

## Record the Migration

Append to `~/CLAUDE.md` on this VM:

```markdown
## Active work moved to child VM
- VM: <name> (<ip>)
- Moved: <YYYY-MM-DD>
- Reason: <what needed root>
- Resume: SSH into child VM, continue from ~/
```
